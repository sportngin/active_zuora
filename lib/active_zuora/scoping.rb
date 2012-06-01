module ActiveZuora
  module Scoping

    extend ActiveSupport::Concern

    included do
      class << self

        # Delegate to :scoped
        delegate :find, :all, :to => :scoped
        delegate :select, :where, :and, :or, :to => :scoped
        delegate :first, :last, :each, :map, :any?, :empty?, :blank?, :present?, :size, :count, :to => :scoped

        # Keep track of a current scope.
        attr_accessor :current_scope

      end
    end

    module ClassMethods

      def scoped
        current_scope || relation
      end

      def unscoped
        block_given? ? relation.scoped { yield } : relation
      end

      def exclude_from_queries(*field_names)
        (@excluded_from_queries ||= []).concat field_names.map(&:to_sym)
      end

      def relation
        query_field_names = field_names - (@excluded_from_queries ||= [])
        Relation.new(self, query_field_names)
      end

      def scope(name, body)
        # Body can be a Relation or a lambda that returns a relation.
        define_singleton_method(name) do |*args|
          body.respond_to?(:call) ? body.call(*args) : scoped.merge(body)
        end
      end

    end

  end
end

