module ActiveZuora
  class DecimalField < Field

    def type_cast(value)
      return value if value.nil? || value.is_a?(BigDecimal)
      return default if value.blank?
      return value.to_d if value.respond_to?(:to_d)
      default
    end

  end
end