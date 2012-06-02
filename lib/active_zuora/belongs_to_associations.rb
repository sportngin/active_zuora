module ActiveZuora
  module BelongsToAssociations

    extend ActiveSupport::Concern

    module ClassMethods

      def belongs_to(item, options={})
        class_name = options[:class_name] || nested_class_name(item.to_s.camelize)
        foreign_key = options[:foreign_key] || :"#{item}_id"
        # Add the field if it doesn't already exist.
        field foreign_key, :string unless field? foreign_key
        ivar = "@#{item}"
        loaded_ivar = "@#{item}_loaded"
        # Define the methods on an included module, so we can override
        # them using super.
        generated_attribute_methods.module_eval do
          define_method(item) do
            # Return the object if it was already loaded.
            if instance_variable_get(loaded_ivar)
              return instance_variable_get(ivar)
            else
              # Otherwise find it.
              record = class_name.constantize.find self.send(foreign_key)
              send("#{item}=", record)
              record
            end
          end
          define_method("#{item}=") do |record|
            instance_variable_set(loaded_ivar, true)
            instance_variable_set(ivar, record)
            # Set the foreign key id attribute as well.
            write_attribute(foreign_key, record.try(:id))
            record          
          end
          redefine_method("#{foreign_key}=") do |item_id|
            item_id = write_attribute(foreign_key, item_id)
            # Unload the object if the id is different.
            if send("#{item}_loaded?") && send(item).id != item_id
              instance_variable_set(loaded_ivar, false)
            end
            item_id
          end
          define_method("#{item}_loaded?") do
            instance_variable_get(loaded_ivar) || false
          end
          define_method("reload_#{item}") do
            instance_variable_set(loaded_ivar, false)
            send(item)
          end
        end
      end

    end
  end
end
