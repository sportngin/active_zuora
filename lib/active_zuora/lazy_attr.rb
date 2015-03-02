module ActiveZuora
  module LazyAttr

    # This is meant to be included onto an Invoice class.
    # Returns true/false on success.
    # Result hash is stored in #result.
    # If success, the id will be set in the object.
    # If failure, errors will be present on object.

    extend ActiveSupport::Concern

    included do
      include Base
    end


    def fetch_field(field_name)
      return nil unless self.id

      records = fetch_field_records("select #{self.class.get_field!(field_name).zuora_name} from #{zuora_object_name} where Id = '#{self.id}'")
      type_cast_fetched_field(field_name, records.nil? ? nil : records[field_name.to_sym])
    end
    private :fetch_field

    def fetch_field_records(query_string)
      response = self.class.connection.request(:query){ |soap| soap.body = { :query_string => query_string } }
      response[:query_response][:result][:records]
    end
    private :fetch_field_records

    def type_cast_fetched_field(field_name, value)
      get_field!(field_name).type_cast(value)
    end
    private :type_cast_fetched_field

    module ClassMethods
      def lazy_load(*field_names)
        Array(field_names).map(&:to_sym).each do |field_name|
          define_lazy_field field_name
        end
      end

      def define_lazy_field(field)
        instance_eval do
          define_method field do
            instance_variable_get("@#{field}") || instance_variable_set("@#{field}", fetch_field(field))
          end
        end
      end
    end
  end
end
