module ActiveZuora
  class ArrayFieldDecorator < SimpleDelegator

    # Wraps a Field object and typecasts/builds
    # item as an array of the given field.

    def type_cast(values)
      # Force into an array and run type_cast on each element.
      [values].flatten.compact.map { |value| __getobj__.type_cast(value) }
    end

    def build_xml(xml, soap, values, options={})
      # It may be wierd that we're mapping and taking the last value,
      # But there's an issue with xml builder where if a block
      # returns an array, it will output the array in the XML.
      # So instead, we'll have our block return the value
      # of the last build_xml call.
      [values].flatten.map do |value|
        __getobj__.build_xml(xml, soap, value, options)
      end.last
    end

  end
end
