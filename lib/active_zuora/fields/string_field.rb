module ActiveZuora
  class StringField < Field

    def type_cast(value)
      return value if value.nil? || value.is_a?(String)
      return value.to_s if value.respond_to?(:to_s)
      default
    end

  end
end