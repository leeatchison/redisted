#
#
# Creates the following Redis keys for a class named "Model"
#
# model:<id> -- HASH -- contains all attributes of the class
# model_id -- Last ID used (integer used with INCR command)
#
#
module Redisted
  class Base
    include ActiveModel::MassAssignmentSecurity
    include ActiveModel::Validations
    include ActiveModel::Serialization
    #include ActiveModel::Dirty -- This model doesn't match very well...
    extend ActiveModel::Callbacks
    extend ActiveModel::Naming
    extend ActiveModel::Translation

    define_model_callbacks :create, :update, :save, :destroy

    def initialize(attrs = nil,redis=nil)
      @redis=redis||Base.redis
      validate_redis
      init_fields
      init_attributes
      init_indexes
      init_references
      self.attributes=attrs if attrs
      self
    end
    def redis= conn=nil
      @redis=conn||@@redis
      validate_redis
      @redis
    end
    def redis
      validate_redis
      @redis
    end
    def prefix
      self.class.prefix
    end
    def id # NOTE: ID is read/only - it can only be set via the load method
      @id
    end
    def to_attr_type key,value
      raise InvalidField,"Unknown field: #{key}" if fields[key].nil?
      return nil if value.nil?
      case fields[key][:type]
        when :string then value
        when :symbol then value.to_sym
        when :integer then value.to_i
        when :datetime then value.to_datetime
        else
          value
        end
    end
    def to_redis_type key,value
      return nil if value.nil?
      case fields[key][:type]
        when :string then value
        when :symbol then value.to_s
        when :integer then value.to_i.to_s
        when :datetime then value.utc.to_s
        else
          value
      end
    end
    def method_missing(id, *args)
      fields.each do |field,options|
        return get_attr(field) if id==field
        return set_attr(field,args[0]) if id.to_s==field.to_s+"="
      end
      references.each do |ref,options|
        return get_reference(ref,options) if id==ref
        return set_reference(ref,options,args[0]) if id.to_s==ref.to_s+"="
      end
      super
    end

    private
    def validate_redis
      raise RedisConnectionNotDefined if @redis.nil?
    end

    def generate_id
      validate_redis
      @@redis.incr "#{prefix}_id"
    end


    def get_obj_option key
      self.class.get_obj_option key
    end
    def set_obj_option key,val
      self.class.set_obj_option key,val
    end
    class << self
      def get_obj_option key
        @obj_options||={}
        @obj_options[key]
      end
      def set_obj_option key,val
        @obj_options||={}
        @obj_options[key]=val
      end
      def is_redisted_model?
        true
      end
      def redis= conn
        @@redis=conn
      end
      def redis
        @@redis
      end
      def prefix
        ret=self.model_name.i18n_key
        ret
      end

      private

      def validate_redis
        raise RedisConnectionNotDefined if @@redis.nil?
      end

    end
  end
end
