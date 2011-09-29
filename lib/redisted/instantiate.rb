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
            m=Message.new
            m.load id
            ret << m
          end
          ret
        else
          m=Message.new
          m.load ids
          m
        end
      end
    end
    def load id
      @id=id
      self
    end
  end
end
