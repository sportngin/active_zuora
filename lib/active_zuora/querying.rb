module ActiveZuora
  module Querying

    extend ActiveSupport::Concern

    included do
      class << self
        delegate :select, :where, :all, :as_hashes, :to => :query
      end
    end

    module ClassMethods

      def exclude_from_queries(*field_names)
        (@excluded_from_queries ||= []).concat field_names.map(&:to_sym)
      end

      def query
        query_field_names = field_names - (@excluded_from_queries ||= [])
        Query.new(self, query_field_names)
      end

      def find(id)
        return nil if id.blank?
        where(:id => id).first
      end

    end

  end
end

