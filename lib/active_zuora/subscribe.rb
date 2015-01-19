module ActiveZuora
  module Subscribe

    # This is meant to be included onto a SubscribeRequest class.
    # Returns true/false on success.
    # Result hash is stored in #result.
    # If success, the subscription id and account id will be set in those objects.
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
      if result[:success]
        account.id = result[:account_id]
        subscription_data.subscription.id = result[:subscription_id]
        clear_changed_attributes
        true
      else
        add_zuora_errors(result[:errors])
        false
      end
    end

    def subscribe!
      raise "Could not subscribe: #{errors.full_messages.join ', '}" unless subscribe
    end

  end
end