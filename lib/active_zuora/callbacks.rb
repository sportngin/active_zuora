module ActiveZuora
  module Callbacks

    extend ActiveSupport::Concern

    included do
      extend ActiveModel::Callbacks

      define_model_callbacks :initialize, only: :after

      def initialize(attributes = {})
        run_callbacks :initialize do
          super(attributes)
        end
      end
    end

    module ClassMethods
      def default(field, options = {})
        after_initialize { self.send("#{field}=", options[:to]) unless self.send("#{field}") }
      end
    end

  end
end
