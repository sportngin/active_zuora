module ActiveZuora
  class DateField < Field

    def type_cast(value)
      return value if value.nil?
      return value.to_date if value.is_a?(Date)
      return value.to_date if value.is_a?(DateTime)
      value.to_date rescue default
    end

    def build_xml(xml, soap, value, options={})
      value = value ? value.strftime("%Y-%m-%d") : ''
      super(xml, soap, value, options)
    end

  end
end

