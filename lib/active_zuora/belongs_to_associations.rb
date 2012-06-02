module ActiveZuora
  module BelongsToAssociations

    extend ActiveSupport::Concern

    module ClassMethods

      def belongs_to(item, options={})
        class_name = options[:class_name] || nested_class_name(item.to_s.camelize)
        foreign_key = options[:foreign_key] || :"#{item}_id"
        ivar = "@#{item}"
        loaded_ivar = "@#{item}_loaded"
        # Define the methods on an included module, so we can override
        # them using super.
        generated_attribute_methods.module_eval do
          define_method("#{item}_loaded?") do
            instance_variable_get(loaded_ivar) || false
          end
          define_method("reload_#{item}") do
            instance_variable_set(loaded_ivar, false)
            send(item)
          end
          define_method(item) do
            if instance_variable_get(loaded_ivar)
              return instance_variable_get(ivar)
            else
              record = class_name.constantize.find self.send(foreign_key)
              instance_variable_set(loaded_ivar, true)
              instance_variable_set(ivar, record)
              record
            end
          end
          define_method("#{item}=") do |record|
            instance_variable_set(loaded_ivar, true)
            instance_variable_set(ivar, record)
            send("#{foreign_key}=", record.try(:id))
            record          
          end
        end
      end

    end
  end
end
