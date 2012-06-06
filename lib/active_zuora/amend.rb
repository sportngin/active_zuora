module ActiveZuora
  module Amend

    # This is meant to be included onto a AmendRequest class.
    # Returns true/false on success.
    # Result hash is stored in #result.
    # If success, the ids will be set in the given amendments.
    # If failure, errors will be present on object.

    extend ActiveSupport::Concern

    included do
      include Base
      attr_accessor :result
    end

    def amend
      self.result = self.class.connection.request(:amend) do |soap|
        soap.body do |xml| 
          build_xml(xml, soap, 
            :namespace => soap.namespace,
            :element_name => :requests,
            :force_type => true)
        end
      end[:amend_response][:results]
      if result[:success]
        [result[:amendment_ids]].flatten.compact.each_with_index do |id, i|
          amendments[i].id = id
        end
        clear_changed_attributes
        true
      else
        add_zuora_errors(result[:errors])
        false
      end
    end

    def amend!
      raise "Could not amend: #{errors.full_messages.join ', '}" unless amend
    end

  end
end