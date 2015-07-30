require 'active_zuora/fields/field'
require 'active_zuora/fields/boolean_field'
require 'active_zuora/fields/date_field'
require 'active_zuora/fields/date_time_field'
require 'active_zuora/fields/decimal_field'
require 'active_zuora/fields/integer_field'
require 'active_zuora/fields/object_field'
require 'active_zuora/fields/string_field'
require 'active_zuora/fields/array_field_decorator'

module ActiveZuora
  module Fields

    extend ActiveSupport::Concern

    included do
      include ActiveModel::Dirty
      delegate :fields, :field_names, :field?, :get_field, :get_field!,
        :default_attributes, :to => 'self.class'
    end

    def initialize(attributes={})
      # Start with defaults, and override those with the given attributes.
      self.attributes = default_attributes.merge(attributes)
    end

    def attributes
      # A requirement of ActiveModel::Attributes.
      # Hash must use string keys.
      attributes = {}
      fields.each { |field| attributes[field.name] = send(field.name) }
      attributes
    end

    def attributes=(attributes)
      attributes.each { |key, value| send("#{key}=", value) }
    end

    def untracked_attributes=(attributes)
      # Loads attributes without tracking dirt.
      self.attributes = attributes
      clear_changed_attributes
      attributes
    end

    def write_attribute(name, value)
      field = get_field!(name)
      value = field.type_cast(value)
      attribute_will_change!(name) if value != send(name)
      instance_variable_set("@#{name}", value)
      value
    end

    def clear_changed_attributes
      changed_attributes.clear
      # If we have any fields that are also Base objects,
      # clear their attributes as well.
      fields.each { |field| field.clear_changed_attributes(send(field.name)) }
    end

    module ClassMethods

      def fields_by_name
        # { :field_name_symbol => field_object }
        @fields ||= {}
      end

      def fields
        fields_by_name.values
      end

      def field_names
        fields_by_name.keys
      end

      def field?(name)
        fields_by_name.key?(name.to_sym)
      end

      def add_field(name, field)
        fields_by_name[name.to_sym] = field
        # Define the setters, getters, and changed helpers.
        field.define_instance_methods(self)
      end

      def get_field(name)
        fields_by_name[name.to_sym]
      end

      def get_field!(name)
        get_field(name) || raise(ArgumentError.new("No field in #{self} named #{name}"))
      end

      def field(name, type, options={})
        # Check if this field should be an array, don't pass
        # this option down to the field.
        field_is_array = options.delete(:array) || false
        # Create and register the field.
        field = case type
          when :string   then StringField.new(name, namespace, options)
          when :boolean  then BooleanField.new(name, namespace, options)
          when :integer  then IntegerField.new(name, namespace, options)
          when :decimal  then DecimalField.new(name, namespace, options)
          when :date     then DateField.new(name, namespace, options)
          when :datetime then DateTimeField.new(name, namespace, options)
          when :object
            class_name = options[:class_name] || nested_class_name(name.to_s.camelize)
            ObjectField.new(name, namespace, class_name, options)
          else
            ArgumentError.new "Unknown field type: #{type}"
          end
        field = ArrayFieldDecorator.new(field) if field_is_array
        add_field(name, field)
      end

      def default_attributes
        default_attributes = {}
        fields.each { |field| default_attributes[field.name] = field.default }
        default_attributes
      end

    end
  end
end
