module ActiveZuora
  module BillingPreview

    # This is meant to be included onto an BillingPreviewRequest class.
    # Returns a BillingPreviewResponse object on success.
    # Result hash is stored in #result.
    # If failure, errors will be present on object.

    extend ActiveSupport::Concern

    included do
      include Base
      attr_accessor :result
    end

    def billing_preview
      self.result = self.class.connection.request(:billing_preview) do |soap|
        soap.body do |xml|
          build_xml(xml, soap,
            :namespace => soap.namespace,
            :element_name => :requests,
            :force_type => true)
        end
      end[:billing_preview_response][:results]

      if result[:success]
        clear_changed_attributes
        filtered_invoice_items = self.result[:invoice_item].map do |invoice_item|
          #Filter out data in the return value that are not valid invoice item fields such as
          #    :"@xmlns:ns2"=>"http://object.api.zuora.com/",
          #    :"@xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
          #    :"@xsi:type"=>"ns2:InvoiceItem"
          invoice_item.select{|key, v| ActiveZuora::InvoiceItem.field_names.include?(key)}
        end
        ActiveZuora::BillingPreviewResult.new(self.result.merge(invoice_item: filtered_invoice_items))
      else
        add_zuora_errors(result[:errors])
        false
      end
    end

    def billing_preview!
      billing_preview.tap do |preview|
        raise "Could not billing preview: #{errors.full_messages.join ', '}" unless preview
      end
    end

  end
end
