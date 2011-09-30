module Redisted
  class Base
    #
    #
    # Relation
    #
    #
    class Relation
      def initialize the_class,redis,scopes,indices
        @the_class=the_class
        @redis=redis
        @scopes=scopes
        @indices=indices
        @is_in_list=[]
      end
      #
      # Low Level Setup Conditions
      #
      def is_in index_name,*args
        index=@indices[index_name.to_sym]
        raise InvalidQuery,"Could not find index '#{index_name}'" if index.nil?
        if index[:match]
          raise InvalidQuery,"No parameter provided to index when one was expected" if args.size!=1
        else
          raise InvalidQuery,"Parameter provided to index when not expected" if args.size!=0
        end
        @is_in_list<<{:index_name=>index_name,:index=>index,:args=>args}
        self
      end
      def internal_add_reference redis_key
        @is_in_list<<{
          :index_name=>nil,
          :args=>nil,
          :index=>{
            :redis_key=>redis_key
          }
        }
      end



      #
      # Calculate Results
      #
      def first
        key=merge_keys @is_in_list
        id=nil
        if key
          id_list=@redis.zrange key,0,-1 # LEELEE: Performance improve...
          raise InvalidQuery,"No keys" if id_list.size==0
          id=id_list.first
        else
          keyprefix="#{prefix}:"
          key_list=@redis.keys "#{keyprefix}*"
          raise InvalidQuery,"No keys" if key_list.size==0
          id=id_list.first[keyprefix.size..-1]
        end
        obj=@the_class.new
        obj.load id
        obj
      end
      def last
        key=merge_keys @is_in_list
        id=nil
        if key
          id_list=@redis.zrange key,0,-1 # LEELEE: Performance improve...
          raise InvalidQuery,"No keys" if id_list.size==0
          id=id_list.last
        else
          keyprefix="#{prefix}:"
          key_list=@redis.keys "#{keyprefix}*"
          raise InvalidQuery,"No keys" if key_list.size==0
          id=id_list.last[keyprefix.size..-1]
        end
        obj=@the_class.new
        obj.load id
        obj
      end
      def all
        ret=[]
        key=merge_keys @is_in_list
        if key
          id_list=@redis.zrange key,0,-1
          id_list.each do |id|
            obj=@the_class.new
            obj.load id
            ret<<obj
          end
        else
          keyprefix="#{prefix}:"
          key_list=@redis.keys "#{keyprefix}*"
          key_list.each do |key|
            obj=@the_class.new
            obj.load key[keyprefix.size..-1]
            ret<<obj
          end
        end
        ret
      end
      def each &proc
        key=merge_keys @is_in_list
        if key
          id_list=@redis.zrange key,0,-1
          id_list.each do |id|
            obj=@the_class.new
            obj.load id
            proc.call(obj)
          end
        else
          keyprefix="#{prefix}:"
          key_list=@redis.keys "#{keyprefix}*"
          key_list.each do |key|
            obj=@the_class.new
            obj.load key[keyprefix.size..-1]
            proc.call(obj)
          end
        end
        nil
      end
      def delete_all
        # TODO: Don't instantiate the object for delete...do it manually...
        #self.each do |m|
        #  m.delete
        #end
      end
      def destroy_all
        self.each do |m|
          m.destroy
        end
      end
      def method_missing(id, *args)
        return add_one args[0] if id.to_s=="<<"
        return @scopes[id].call(*args) if @scopes[id]
        return is_in id[3..-1],*args if id[0,3]=="by_"
        super
      end

      private
      def prefix
        @the_class.prefix
      end
      def merge_keys list
        return nil if list.size==0
        return key_name(list.first) if list.size==1
        cnt=@redis.incr "redisted_tmp_id"
        # TODO: Handle calculating if weights should be used...
        tmpkey="redisted_tmp[#{cnt}]"
        key_list=[]
        @is_in_list.each do |index|
          key_list<<key_name(index)
        end
        @redis.zinterstore tmpkey,key_list,{:aggregate=>:sum,:weight=>3}
        @redis.expire tmpkey,3600 # TODO: Value should be configurable...
        return tmpkey
      end
      def key_name index
        ret=index[:index][:redis_key]
        ret+=":#{index[:args][0]}" if index[:index][:match]
        ret
      end

      #
      #
      # Add objects to a relation
      #
      #
      def add_one val
        @is_in_list.each do |index|
          next if !index[:index_name].nil?
          @redis.zadd index[:index][:redis_key],1,val.id
        end
      end

    end

    class << self
      def scoped
        Relation.new self,@@redis,scopes,indices
      end
      def method_missing(id,*args,&proc)
        is_scoped=(id[0]=='_')
        is_scoped||=[:first,:last,:all,:each,:delete_all,:destroy_all,:where,:limit,:offset,:order,:reverse_order].include? id.to_sym
        is_scoped||= !scopes[id.to_sym].nil?
        is_scoped||= (id[0,3]=="by_")
        return scoped.send(id,*args,&proc) if is_scoped
        super
      end
    end
  end
end
