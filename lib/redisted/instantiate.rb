module Redisted
  class Base
    class << self
      #
      # Use
      #
      def create attrs=nil,redis=nil
        ret=new attrs,redis
        ret.save
        ret
      end
      def find ids
        if ids.is_a? Array
          ret=[]
          ids.each do |id|
            m=new
            m.load id
            ret << m
          end
          ret
        else
          m=new
          m.load ids
          m
        end
      end
    end
    def load id
      @id=id
      pre_cache_values if get_obj_option(:pre_cache_all) and get_obj_option(:pre_cache_all)[:when]==:create
      self
    end
  end
end
