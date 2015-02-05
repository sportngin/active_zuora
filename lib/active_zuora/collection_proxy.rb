module ActiveZuora
  class CollectionProxy
    
    include ZObject
    include Enumerable
    include BatchSubscribe
    
    attr_reader :records, :zobject_class

    def initialize(ary = [])
      unless ary.empty?
        raise "objects in collection must be ActiveZuora object instances" unless class_names = ary.map{|object| object.zuora_object_name}.uniq
        raise "objects in collection must be ActiveZuora object instances of the same class" unless class_names.length == 1
        @zobject_class = class_names.first
      end
      @records = ary
    end
    
    def add object
      raise "object must be an ActiveZuora object instance" unless object.zuora_object_name
      if records.empty?
        @zobject_class = object.zuora_object_name
      else
        raise "object must be must be ActiveZuora object instances of the same class as other elements in the Collection" unless object.zuora_object_name == zobject_class
      end
      @records.push object
    end

    def each
      records.each { |r| yield r }
    end
     
    def empty?
      records.empty?
    end
    
  end
end