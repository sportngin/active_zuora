module ActiveZuora
  class BooleanField < Field
    
    def type_cast(value)
      return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      return true if value.to_s.downcase == 'true'
      return false if value.to_s.downcase == 'false'
      default
    end

  end
end