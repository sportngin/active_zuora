module ActiveZuora
  class IntegerField < Field
    
    def type_cast(value)
      return value if value.nil? || value.is_a?(Integer)
      return value.to_i if value.respond_to?(:to_i)
      default
    end

  end
end