module ActiveZuora
  class Field

    attr_accessor :name, :zuora_name, :default, :namespace

    def initialize(name, namespace, options={})
      @name = name.to_s
      @namespace = namespace
      @zuora_name = options[:zuora_name] || @name.camelize
      @default = options[:default]
    end

    def type_cast(value)
      value
    end

    def define_instance_methods(zuora_class)
      # We store this into a variable so we can use it in our
      # class eval below.
      field_name = name
      # Add dirty helpers
      # The value will still be stored in an instance
      # variable with the name of the field.
      # But we'll define extra writer methods so that we
      # can handle any input from savon.
      # Savon just calls underscore on the element names,
      # but our fields allow for any combination
      # of field name and Zuora name.
      # This is especially useful for custom fields which
      # are named like CustomField__c.  You might choose
      # to make this field :custom_field, and therefore
      # we'll need a writer for :custom_field, :custom_field_c,
      # and I threw in a :CustomField__c just for good measure.      
      writers = [field_name, zuora_name, zuora_name.underscore].uniq
      zuora_class.class_eval do
        # Define the methods on an included module, so we can override
        # them using super.
        generated_attribute_methods.module_eval do
          # Getter
          attr_reader field_name
          # Boolean check.
          define_method "#{field_name}?" do
            !!send(field_name)
          end
          # Writers
          writers.each do |writer_name|
            define_method "#{writer_name}=" do |value|
              write_attribute(field_name, value)
            end
          end
        end
        # Dirty attribute helpers.
        define_attribute_methods [field_name]
      end
    end

    def build_xml(xml, soap, value, options={})
      qualifier = soap.namespace_by_uri(namespace)
      nil_strategy = options[:nil_strategy] || :omit
      # The extra qualifiers attribute needs to be passed in
      # in case the field is another complexType that needs
      # to be namespaced.
      if !value.nil? || nil_strategy == :whitespace
        xml.tag!(qualifier, zuora_name.to_sym, value.to_s)
      elsif nil_strategy == :fields_to_null
        xml.tag!(qualifier, :fieldsToNull, zuora_name.to_sym)
      end
    end

    def clear_changed_attributes(value)
      # If the value of this field has attribute changes to clear,
      # override this function.
    end

  end
end