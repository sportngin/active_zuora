module ActiveZuora
  module Subscribe

    # This is meant to be included onto a SubscribeRequest class.
    # Returns true/false on success.
    # Result hash is stored in #result.
    # If failure, errors will be present on object.

    extend ActiveSupport::Concern

    included do
      include Base
      attr_accessor :result
    end

    def subscribe
      self.result = self.class.connection.request(:subscribe) do |soap|
        soap.body do |xml| 
          build_xml(xml, soap, 
            :namespace => soap.namespace,
            :element_name => :subscribes,
            :force_type => true)
        end
      end[:subscribe_response][:result]
      add_zuora_errors(result[:errors])
      result[:success]
    end

    def subscribe!
      raise "Could not subscribe: #{errors.full_messages.join ', '}" unless subscribe
    end

  end
end