module ActiveZuora
  class HasManyProxy

    # Wraps around the Relation representing a has_many association
    # to add features like inverse_of loading.

    attr_reader :scope, :owner

    delegate :"==", :"===", :"=~", :inspect, :to_s, :to => :to_a
    
    def initialize(owner, scope, options={})
      @owner, @scope = owner, scope
      # inverse_of by default. You can opt out with :inverse_of => false
      @inverse_of = (options[:inverse_of] || owner.zuora_object_name.underscore) unless options[:inverse_of] == false
    end

    def to_a
      if @scope.loaded? || !@inverse_of
        @scope.to_a
      else
        @scope.to_a.each { |record| record.send("#{@inverse_of}=", owner) }
        @scope.to_a
      end
    end

    alias :all :to_a

    def reload
      # If reload is called directly on the scope, it will reload
      # without our extra functionality, like inverse_of loading.
      @scope.unload
      to_a
    end

    protected

    def method_missing(method, *args, &block)
      # If we do anything that needs loading the scope, then we'll load it.
      if Array.method_defined?(method)
        to_a.send(method, *args, &block)
      else
        # Otherwise send all messages to the @scope.
        @scope.send(method, *args, &block)
      end
    end

  end
end


