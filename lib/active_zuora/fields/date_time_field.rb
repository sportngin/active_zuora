module ActiveZuora
  class DateTimeField < Field

    def type_cast(value)
      return value if value.nil? || value.is_a?(Date)
      return value.to_datetime if value.is_a?(Time)
      value.to_datetime rescue default
    end

    def build_xml(xml, soap, value, options={})
      # All dates need to be in PST time.  Since all user-set attributes
      # in Zuora are really only dates, we'll chop off the time.
      # 2012-05-22T00:00:00-08:00
      value = value ? value.strftime("%Y-%m-%dT00:00:00") : ''
      super(xml, soap, value, options)
    end

  end
end
