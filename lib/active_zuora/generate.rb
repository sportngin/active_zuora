module ActiveZuora
  module Generate

    # This is meant to be included onto an Invoice class.
    # Returns true/false on success.
    # Result hash is stored in #result.
    # If success, the id will be set in the object.
    # If failure, errors will be present on object.

    extend ActiveSupport::Concern

    included do
      include Base
      attr_accessor :result
    end

    def generate
      self.result = self.class.connection.request(:generate) do |soap|
        soap.body do |xml|
          build_xml(xml, soap,
            :namespace => soap.namespace,
            :element_name => :zObjects,
            :force_type => true)
        end
      end[:generate_response][:result]

      if result[:success]
        self.id = result[:id]
        self.status = 'Draft'
        clear_changed_attributes
        true
      else
        add_zuora_errors(result[:errors])
        false
      end
    end

    def generate!
      raise "Could not generate: #{errors.full_messages.join ', '}" unless generate
    end

  end
end
