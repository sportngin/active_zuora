require 'bigdecimal'
require 'bigdecimal/util'

module ActiveZuora
  module Base

    extend ActiveSupport::Concern

    # This is the default connection object to use for all Base classes.
    # Each individual Base class can overwrite it.
    class << self
      attr_accessor :connection
    end

    included do
      include Fields
      include ActiveModel::Validations
      include BelongsToAssociations
      class << self
        attr_accessor :namespace
        attr_writer :zuora_object_name
        attr_writer :connection
      end
      delegate :namespace, :zuora_object_name, :to => 'self.class'
    end

    def xml_field_names
      # Which field names should be rendered during build_xml.
      # Choose only field names that have been changed.
      # Make sure the order in fields is maintained.
      field_names & changed.map(&:to_sym)
    end

    def build_xml(xml, soap, options={})
      namespace = options.delete(:namespace) || self.namespace
      qualifier = soap.namespace_by_uri(namespace)
      custom_element_name = options.delete(:element_name)
      element_name = custom_element_name || zuora_object_name
      attributes = options.delete(:force_type) ? 
        { "xsi:type" => "#{qualifier}:#{zuora_object_name}" } : {}

      xml.tag!(qualifier, element_name.to_sym, attributes) do
        xml_field_names.map { |field_name| get_field!(field_name) }.sort(&method(:fields_order)).each do |field|
          field.build_xml(xml, soap, send(field.name), options)
        end
      end
    end

    def fields_order(a, b)
      if send(a.name) == nil
        send(b.name) == nil ? 0 : -1
      elsif a.name.to_sym == :id
        send(b.name) == nil ? 1 : -1
      else
        (b.name.to_sym == :id || send(b.name) == nil) ? 1 : 0
      end
    end

    def add_zuora_errors(zuora_errors)
      return if zuora_errors.blank?
      zuora_errors = [zuora_errors] unless zuora_errors.is_a?(Array)
      zuora_errors.each { |error| errors.add(:base, error[:message].capitalize) }
    end

    module ClassMethods

      def zuora_object_name
        @zuora_object_name ||= self.name.split("::").last
      end

      def connection
        @connection || Base.connection
      end

      def nested_class_name(unnested_class_name)
        # This helper method will take a class name, and nest it inside
        # the same module/class as self.
        (name.split("::")[0..-2] << unnested_class_name).join("::")
      end

    end

  end
end