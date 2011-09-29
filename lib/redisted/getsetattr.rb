module Redisted
  class Base
    private
    def init_attributes
      @attributes_value={}
      @attributes_status={}
      @attributes_old={}
      @attributes_old_status={}
      @cached_sets=false
    end
    public
    def set_attr key,val
      key=key.to_sym
      val=to_redis_type key,val
      if @cached_sets or !persisted?
        if (@attributes_status[key]==:cached)
          # If we have it, we save the old value when first marked dirty...
          @attributes_old[key]=@attributes_value[key]
          @attributes_old_status[key]=:cached
        end
        @attributes_value[key]=val
        @attributes_status[key]=:dirty
      else
        index_process({key=>val}) do
          @attributes_value[key]=val
          @attributes_status[key]=:cached
          @redis.hset "#{prefix}:#{@id}",key,val
          @attributes_old[key]=nil
          @attributes_old_status[key]=nil
        end
      end
    end
    def get_attr key
      key=key.to_sym
      return to_attr_type(key,@attributes_value[key]) if [:cached,:dirty].include?(@attributes_status[key])
      return nil if !persisted?
      ret=to_attr_type key,@redis.hget("#{prefix}:#{@id}",key)
      @attributes_value[key]=ret
      @attributes_status[key]=:cached
      ret
    end

    def clear key=nil
      if key.nil?
        @@field_list.each do |key,val|
          raise IsDirty,"#{key} is dirty" if (!key.nil?) and @attributes_status[key]==:dirty
        end
      end
      setup_attributes
      nil
    end
    def fill_cache keys=nil
      if keys.nil?
        keys=[]
        @@field_list.each do |key,val|
          next if !@attributes_status[key].nil?
          keys << key
        end
      end
      if keys.size>0
        ret=@redis.hmget  "#{prefix}:#{@id}",*keys
        idx=0
        keys.each do |key|
          key=key.to_sym
          @attributes_value[key]=ret[idx]
          @attributes_status[key]=:cached
          idx+=1
        end
      end
      self
    end
    def persisted?
      !@id.nil?
    end
    def cached? key
      return true if !persisted?
      return [:cached,:dirty].include?(@attributes_status[key])
    end
    def dirty? key
      return true if !persisted?
      return @attributes_status[key]==:dirty
    end
    def saved?
      return false if !persisted?
      @@field_list.each do |key,val|
        return false if @attributes_status[key]==:dirty
      end
      return true
    end
    def cache
      if block_given?
        previous_cached_sets=nil
        begin
          previous_cached_sets=@cached_sets
          @cached_sets=true
          yield
          save if !previous_cached_sets
          @cached_sets=previous_cached_sets
        rescue Exception
          @cached_sets=previous_cached_sets
          raise
        end
      else
        @cached_sets=true
      end
    end
    def cache! &proc
      begin
        @cached_sets=true
        proc.call *attrs
        save!
      rescue Exception
        @cached_sets=false
        raise
      end
    end
    def attributes= attrs
      cache do
        attrs.each do |key,value|
          set_attr key,value
        end
      end
    end
    def attributes load_all=true
      fill_cache if load_all
      @attributes_value.merge id: @id
    end

    def save!
      raise Redisted::RecordInvalid if !valid?
      internal_save_with_callbacks
    end

    def save options={}
      begin
        if (options[:validate].nil? or options[:validate])
          raise Redisted::RecordInvalid if !valid?
        end
        internal_save_with_callbacks
      rescue Exception=>err
        self.errors[:base] = err.to_s
        return false
      end
      true
    end

    private
    def internal_save_with_callbacks
      cb_run=run_callbacks :save do
        if persisted?
          run_callbacks :update do
            internal_save false
          end
        else
          run_callbacks :create do
            internal_save true
          end
        end
      end
      raise Redisted::RecordInvalid,"Callback link broken" if !cb_run
    end
    def internal_save is_create
      @id=generate_id if is_create
      params={}
      params[:id]=@id if is_create
      @attributes_status.each do |key,value|
        next if value!=:dirty
        params[key]=@attributes_value[key]
      end
      if params.size>0
        index_process(params) do
          @redis.hmset("#{prefix}:#{@id}",*(params.flatten))
          @attributes_status.each do |key,value|
            next if value!=:dirty
            @attributes_status[key]=:cached
          end
          @attributes_old={}
          @attributes_old_status={}
        end
      end
      @hold_writes=false
      self
    end
  end
end
