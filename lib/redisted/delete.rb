module Redisted
  class Base

    def delete
      raise Redisted::RecordInvalid,"Object is not persisted" if self.id.nil?
      @redis.del "#{prefix}:#{self.id}"
      id=nil
      attributes={}
      @attributes_status.clear
      # LEELEE: Also handle indices
      true
    end
    def destroy
      # TODO: Run all the callbacks...
      delete
      # LEELEE: Follow destroy path...
      true
    end

  end
end
