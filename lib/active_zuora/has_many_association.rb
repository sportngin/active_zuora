module ActiveZuora
  module HasManyAssociation

    extend ActiveSupport::Concern

    module ClassMethods

      def has_many(items, options={})
        class_name = options[:class_name] || nested_class_name(items.to_s.singularize.camelize)
        foreign_key = options[:foreign_key] || :"#{zuora_object_name.underscore}_id"
        # inverse_of by default. You can opt out with :inverse_of => false
        inverse_of = (options[:inverse_of] || zuora_object_name.underscore) unless options[:inverse_of] == false
        ivar = "@#{items}"
        define_method("#{items}_loaded?") do
          !instance_variable_get(ivar).nil?
        end
        define_method("reload_#{items}") do
          instance_variable_set(ivar, nil)
          send(items)
        end
        define_method(items) do
          if instance_variable_get(ivar)
            return instance_variable_get(ivar)
          else
            records = class_name.constantize.where(foreign_key => self.id).all
            records.each { |record| record.send("#{inverse_of}=", self) } if inverse_of
            instance_variable_set(ivar, records)
            records
          end
        end
      end

    end
  end
end