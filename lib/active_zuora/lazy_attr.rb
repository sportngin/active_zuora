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
      query_string = "select #{self.class.get_field!(field_name).zuora_name} from #{zuora_object_name} where Id = '#{self.id}'"
      response = self.class.connection.request(:query){ |soap| soap.body = { :query_string => query_string } }
      response[:query_response][:result][:records][field_name.to_sym]
    end
    private :fetch_field

    module ClassMethods
      def lazy_load(*field_names)
        (@lazy_loadded_fields ||= []).concat field_names.map(&:to_sym)
        instance_eval do
          @lazy_loadded_fields.each do |field_name|
            field_var = "@#{field_name}"
            define_method field_name do
              instance_variable_get(field_var) || instance_variable_set(field_var, fetch_field(field_name))
            end
          end
        end
      end
    end
  end
end
