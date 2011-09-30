module Redisted
  class Base
    def references
      self.class.references
    end
    class << self
      def references= val
        @references=val
      end
      def references
        @references||={}
        @references
      end
    end
    private
    def init_references
    end

    def get_reference ref,details
      ret=nil
      # TODO: Can this be cached???
      if details[:ref_type]==:one
        id=get_attr("#{details[:string]}_id".to_sym)
        ret=details[:class].find(id)
      elsif details[:ref_type]==:many
        if details[:model_type]==:redisted
          ret=details[:class].scoped
          ret.internal_add_reference "#{prefix}[#{details[:string]}_id]"
        else
          return [] if @redis.exists "#{prefix}#[{details[:string]}_id]"
          id_list=@redis.zrange "#{prefix}[#{details[:string]}_id]",0,-1
          ret=details[:class].find(id_list)
        end
      end
      ret
    end
    def set_reference ref,details,val
      if details[:ref_type]==:one
        set_attr "#{details[:string]}_id".to_sym,val.id.to_s
      elsif details[:ref_type]==:many
        raise "LEELEE: Not implemented yet"
      end
      nil
    end
    class << self
      public



      #
      # Setup
      #
      def references_one sym,opt={}
        details=name_to_class_details sym,opt[:as]
        raise InvalidReference,"Reference already defined" if !references[details[:symbol]].nil?
        field "#{details[:string]}_id".to_sym
        details[:ref_type]=:one
        references[details[:symbol]]=details
      end
      def references_many sym,opt={}
        details=name_to_class_details sym,opt[:as]
        raise InvalidReference,"Reference already defined" if !references[details[:plural][:symbol]].nil?
        field "#{details[:plural][:string]}_list".to_sym
        details[:ref_type]=:many
        references[details[:plural][:symbol]]=details
      end

      private

      def name_to_class_details obj,alt_name
        if alt_name
          ret={
            symbol: alt_name.to_sym,
            string: alt_name.to_s,
            plural:{
              symbol: alt_name.to_sym,
              string: alt_name.to_s,
            }
          }
        else
          ret={
            symbol: obj.to_sym,
            string: obj.to_s,
            plural:{
              symbol: obj.to_s.pluralize.to_sym,
              string: obj.to_s.pluralize
            }
          }
        end
        ret[:class]=if obj.kind_of? Symbol
                      Kernel.const_get obj.to_s.capitalize
                    else
                      Kernel.const_get obj
                    end
        if ret[:class].respond_to?("is_redisted_model?") and ret[:class].is_redisted_model?
          ret[:model_type]=:redisted
        else
          ret[:model_type]=:other
        end
        ret
      end

    end
  end
end
