module ActiveZuora
  module ZObject
    
    extend ActiveSupport::Concern

    included do
      include Base
      include Querying
      include HasManyAssociation
      include Persistence
      field :id, :string
    end

  end
end