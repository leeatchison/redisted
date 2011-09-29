module Redisted
  class Base
    private
    def init_fields
      @@field_list||={}
      @@scope_list||={}
    end
    class << self
      public
      #
      # Setup
      #
      def field value,options={}
        @@field_list||={}
        options[:type]||=:string
        @@field_list[value]=options
      end
      def fields
        @@field_list
      end
      def scope name,options
        @@scope_list||={}
        @@scope_list[name]=lambdafi_field(options)
      end

      private

      def read_attribute_for_validation key
        get_attr key
      end

      def lambdafi_field options
        lambda do |*args|
          if options.respond_to? :call
            options.call(*args)
          elsif options.is_a? Symbol
            args[0].send(options,*args)
          else
            options # An integer or other constant value
          end
        end
      end

    end
  end
end
