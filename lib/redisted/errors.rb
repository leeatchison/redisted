module Redisted
  class RedisConnectionNotDefined<Exception;end # No redis connection was found
  class RedisSaveFailed<Exception;end
  class RecordInvalid<Exception;end
  class InvalidQuery<Exception;end
  class InvalidReference<Exception;end
  class ValueNotUnique<Exception;end
  class MultiSessionConflict<Exception;end
  class IsDirty<Exception;end
  class InvalidIndex<Exception;end
  class InvalidField<Exception;end
end
