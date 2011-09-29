#
#
# Uniqueness Index:
#
#     index :test_int, unique: true
#         >> An index named "test_int" that verifies that "test_int" is always unique.
#     index :ti, unique: :test_int
#         >> An index named "ti" that verifies that "test_int" is always unique.
#     index :idxkey, unique: [:test_int,:provider]
#         >> An index named "idxkey" that verifies that the "test_int"/"provider" pair is always unique.
#
# Filter/Sort Index:
#
#     index :odd,includes: ->(elem){(elem.test_int%2)!=0}
#         >> An index named "odd" that contains reference to objects who's test_int values are odd numbers.
#     index :asc,order: ->(elem){elem.test_int},fields: :test_int
#         >> An index named "asc" that contains references to *all* objects, sorted by test_int. (only recalculate when :test_int changes)
#     index :sortedodd,includes: ->(elem){(elem.test_int%2)!=0}, order: ->(elem){elem.test_int}
#         >> An index named "sortedodd" that contains reference to objects who's test_int values are odd numbers, sorted by test_int
#     index :provider, match: ->(elem){(elem.provider)}
#         >> Create multiple indices, one for each unique value returned by the match proc. Used for filtering.
#
#
module Redisted
  class Base
    private
    def init_indexes
      @@index_list||={}
    end
    public
    #
    #
    # Setup
    #
    #
    class << self
      def index name,params
        @@index_list||={}
        raise InvalidIndex,"Index redfined: #{name}" if @@index_list[name]
        entry={
            redis_key: "#{prefix}[#{name}]",
            optimistic_retry: params[:optimistic_retry],
        }
        if params[:unique]
          entry[:unique_index]=true
          entry[:fields]= if params[:unique].is_a? Array
                            params[:unique]
                          elsif params[:unique].is_a? Symbol
                            [params[:unique]]
                          else
                            [name]
                          end
        else
          entry[:unique_index]=false
          entry[:includes]=lambdafi_index(params[:includes],true)
          entry[:order]=lambdafi_index(params[:order],1)
          entry[:match]=lambdafi_index(params[:match],"") if params[:match]
          entry[:fields]= if params[:fields].nil?
                            nil
                          elsif params[:fields].is_a? Array
                            params[:fields]
                          elsif params[:fields].is_a? Symbol
                            [params[:fields]]
                          else
                            nil
                          end
        end
        @@index_list[name]=entry
      end
      def lambdafi_index options,default_value
        lambda do |*args|
          ret=nil
          if options.nil?
            ret=default_value
          elsif options.respond_to? :call
            ret=options.call(*args)
          elsif options.is_a? Symbol
            ret=args[0].send(options,*args)
          else
            ret=options # An integer or other constant value...
          end
          ret
        end
      end
    end

    private

    #
    #
    # Process Index:
    #
    # data is a hash of name/value pairs of fields that are going to be changed. The
    # key is the field name, and the value is the *new*, to be assigned, value of the
    # field (not the current value).
    # If the old value is needed, it must be pulled from @attributes_old. If it isn't
    # in @attributes_old, then it must be read from Redis *before* proc.call is made.
    # proc.call should make *set redis calls to update the proper redis keys to implement
    # the desired results. It *cannot* make *get redis calls or any other redis calls that
    # require a return value to be correct (this is because this is executed within a multi).
    # Additionally, @attributes_value must be updated to the new value in this call.
    #
    #
    # TODO: Needs repeat logic for optimistic locking...
    def index_process data,&proc
      state={data: data}
      names=[]
      data.each do |name,value|
        names<<name
      end
      state[:attr_names]=names
      u=uniq_index_start state
      i=index_start state
      @watch_list=[]
      u=uniq_index_watch_setup u
      i=index_watch_setup i
      begin
        if @watch_list.size>0
          @redis.unwatch
          @redis.watch *@watch_list
        end
        u=uniq_index_verify u
        i=index_verify i
        @redis.multi
        begin
          u=uniq_index_multi_start u
          i=index_multi_start i
          proc.call
          u=uniq_index_multi_end u
          i=index_multi_end i
          @redis.exec
        rescue Exception
          @redis.discard
          raise
        end
      rescue Exception
        @redis.unwatch if @watch_list.size>0
        raise
      end
    end

    #
    #
    #
    # Unique Index
    #
    #
    # Creates Key:
    #
    #   SET: model[index_name]
    #
    # Contains all id values from all instances of this model, and is used to verify uniqueness.
    # Maintained during set_attr/save.
    #
    #
    #
    def uniq_index_start state
      state
    end
    def uniq_index_watch_setup state
      # Begin optimistic locking for all indices that are impacted by these changes...
      @@index_list.each do |name,index|
        next if !index[:unique_index]
        next if (index[:fields] & state[:attr_names]).size==0
        @watch_list << index[:redis_key]
      end
      state
    end

    def uniq_index_verify state
      @@index_list.each do |idxname,index|
        next if !index[:unique_index]
        index[:fields].each do |fieldname|
          # if we don't have it, we need to get it now...directly from redis
          if @attributes_old_status[fieldname]!=:cached
            @attributes_old[fieldname]=to_attr_type fieldname,@redis.hget("#{prefix}:#{@id}",fieldname)
            @attributes_old_status[fieldname]=:cached
          end
        end
      end

      cmds_to_do={}
      @@index_list.each do |name,index|
        next if !index[:unique_index]
        next if (index[:fields] & state[:attr_names]).size==0
        # Need to get the old and new index value...
        old=unique_index_value(@attributes_old,index[:fields])
        new=unique_index_value(@attributes_value.merge(state[:data]),index[:fields])
        next if old==new
        cmds_to_do[index[:redis_key]]||={old_vals: [],new_vals: []}
        cmds_to_do[index[:redis_key]][:old_vals] << old if !old.nil?
        cmds_to_do[index[:redis_key]][:new_vals] << new if !new.nil?
      end

      #
      # Verify no value in the "new" list that is not in the "old" list actually exists in the index...
      #
      cmds_to_do.each do |redis_key,cmds|
        (cmds[:new_vals]-cmds[:old_vals]).each do |chk_val|
          raise ValueNotUnique, "Value #{chk_val} is not unique" if @redis.sismember(redis_key,chk_val)
        end
      end

      state[:cmds_to_do]=cmds_to_do
      state
    end
    def uniq_index_multi_start state
      state
    end
    def uniq_index_multi_end state
      state[:cmds_to_do].each do |redis_key,cmds|
        @redis.srem(redis_key,*cmds[:old_vals]) if cmds[:old_vals].size>0
        @redis.sadd(redis_key,*cmds[:new_vals]) if cmds[:new_vals].size>0
      end
      state
    end
    def unique_index_value vals,fields
      ret=[]
      fields.each do |field|
        return nil if vals[field].nil? # If any value is nil, then the whole index is nil...
        ret<<to_redis_type(field,vals[field]) # TODO: Take out ':','%' from the string...encode them instead...
      end
      ret.join(':')
    end

    #
    #
    #
    # Filter/Sort Index
    #
    #
    # Creates Key:
    #
    #   SORTED SET: model[index_name]
    #
    # Contains all id values from instances of this model where the ":includes" proc returns true.
    # If no ":includes" proc is given, then all instances are included. The score for all entries
    # is the value returned by the ":order" proc. If that proc is not specified, then the score
    # will all be 1.
    #
    #
    #
    def index_start state
      state
    end
    def index_watch_setup state
      @@index_list.each do |name,index|
        next if index[:unique_index]
        next if (!index[:fields].nil?) and ((index[:fields] & state[:attr_names]).size==0)
        @watch_list << index[:redis_key]
      end
      attr_old={}
      attr_old_status={}
      @@index_list.each do |name,index|
        next if index[:unique_index]
        # See if we have a "match" field...if so, we need to cache the old values
        if index[:match]
          index[:fields].each do |fieldname|
            # if we don't have it, we need to get it now...directly from redis
            if attr_old_status[fieldname]!=:cached
              attr_old[fieldname]=to_attr_type fieldname,@redis.hget("#{prefix}:#{@id}",fieldname)
              attr_old_status[fieldname]=:cached
            end
          end
        end
      end
      state[:attributes_old]=attr_old
      state[:attributes_old_status]=attr_old_status
      state
    end

    def index_verify state
      state
    end
    def index_multi_start state
      state
    end
    def index_multi_end state
      @@index_list.each do |name,index|
        next if index[:unique_index]
        next if (!index[:fields].nil?) and ((index[:fields] & state[:attr_names]).size==0)

        if index[:match].nil?
          if index[:includes].call(self)
            @redis.zadd index[:redis_key],index[:order].call(self),self.id
          else
            @redis.zrem index[:redis_key],self.id
          end
        else
          old=self.dup
          old.internal_only_force_update_attributes(state[:attributes_old],state[:attributes_old_status])
          old_match_val=index[:match].call(old)
          new_match_val=index[:match].call(self)


          if !old_match_val.nil? and old_match_val!=""
            @redis.zrem "#{index[:redis_key]}:#{old_match_val}",self.id
          end
          if !new_match_val.nil? and new_match_val!=""
            if index[:includes].call(self)
              @redis.zadd "#{index[:redis_key]}:#{new_match_val}",index[:order].call(self),self.id
            end
          end




        end


      end
      state
    end

    public # Unfortunatley, this must be public, even though it should never be called externally
    def internal_only_force_update_attributes attr,status
      @attributes_value=attr
      @attributes_status=status
    end

  end
end
