module ActiveZuora
  module BatchSubscribe

    # This is meant to be included onto the CollectionProxy class.
    # Returns true if every SubscribeRequest was a success
    # Returns false if any single subsciption Request fails
    # Result hash of each subscribe request is stored in the Subscribe Request #result.
    # If success, the subscription id and account id will be set in those objects.
    # If failure, errors will be present on the request object(s) that had error(s).
    
    extend ActiveSupport::Concern

    included do
      include Base
      attr_accessor :result
    end
    
    def batch_subscribe
      raise "object must be an ActiveZuora::CollectionProxy object instance" unless self.zuora_object_name == "CollectionProxy"
      self.result = self.class.connection.request(:subscribe) do |soap|
        soap.body do |xml| 
          inject(xml) do |memo, el|
            el.build_xml(xml, soap, 
              :namespace => soap.namespace,
              :element_name => :subscribes,
              :force_type => true)
          end
        end
      end[:subscribe_response][:result]
      
      self.result = [result] unless result.is_a?(Array)
      result.each_with_index do |result, i|
        self.records[i].result = result
        if result[:success]
          #we assume order is maintained by zuora.  is it?
          self.records[i].account.id = result[:account_id]
          self.records[i].subscription_data.subscription.id = result[:subscription_id]
          self.records[i].clear_changed_attributes
          @status = true
        else
          add_zuora_errors(result[:errors])
          @status = false
        end
      end
      @status
    end
    
    def batch_subscribe!
      raise "Could not batch subscribe: #{errors.full_messages.join ', '}" unless batch_subscribe
    end
  
  end
end
