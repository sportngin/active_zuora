module ActiveZuora
  module ZObject
    
    extend ActiveSupport::Concern

    included do
      include Base
      include Scoping
      include HasManyAssociations
      include Persistence
      field :id, :string
    end
 
    def ==(another_zobject)
      another_zobject.is_a?(ZObject) &&
        zuora_object_name == another_zobject.zuora_object_name && 
        id == another_zobject.id
    end

  end
end