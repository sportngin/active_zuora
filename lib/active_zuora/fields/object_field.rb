module ActiveZuora
  class ObjectField < Field

    # A field that is itself another Zuora complex type.
    # Hashes will automatically be converted to an instance of the given class.

    attr_accessor :class_name

    def initialize(name, namespace, class_name, options={})
      @class_name = class_name
      super(name, namespace, options)
    end

    def type_cast(value)
      if value.is_a?(Hash)
        value = class_name.constantize.new(value)
      end
      value
    end

    def build_xml(xml, soap, value, options={})
      # For complex types, simply omit it if it's nil.
      value.build_xml(xml, soap, :namespace => namespace, :element_name => zuora_name) if value
    end

    def clear_changed_attributes(value)
      value.clear_changed_attributes if value
    end

  end
end