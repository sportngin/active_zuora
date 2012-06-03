module ActiveZuora
  module HasManyAssociations

    extend ActiveSupport::Concern

    module ClassMethods

      def has_many(items, options={})
        class_name = options[:class_name] || nested_class_name(items.to_s.singularize.camelize)
        foreign_key = options[:foreign_key] || :"#{zuora_object_name.underscore}_id"
        conditions = options[:conditions]
        ivar = "@#{items}"
        # Define the methods on an included module, so we can override
        # them using super.
        generated_attribute_methods.module_eval do
          define_method(items) do
            if instance_variable_get(ivar)
              return instance_variable_get(ivar)
            else
              relation = class_name.constantize.where(foreign_key => self.id)
              relation = relation.merge(conditions) if conditions.present?
              proxy = HasManyProxy.new(self, relation, options)
              instance_variable_set(ivar, proxy)
              proxy
            end
          end
        end
      end

    end
  end
end