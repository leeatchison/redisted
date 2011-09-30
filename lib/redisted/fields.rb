module Redisted
  class Base
    def fields
      self.class.fields
    end
    def scopes
      self.class.scopes
    end
    private
    def init_fields
    end
    class << self
      public
      #
      # Setup
      #
      def field value,options={}
        options[:type]||=:string
        fields[value]=options
      end
      def fields
        @fields||={}
        @fields
      end
      def fields= val
        @fields=val
      end
      def scopes
        @scopes||={}
        @scopes
      end
      def scopes= val
        @scopes=val
      end
      def scope name,options
        scopes[name]=lambdafi_field(options)
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
