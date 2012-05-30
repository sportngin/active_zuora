module ActiveZuora
  class Generator

    attr_reader :document, :classes

    def initialize(document, options={})
      # document is a parsed wsdl document.
      @document = document
      @classes = []
      @class_nesting = options[:inside] || ActiveZuora
    end

    def generate_classes
      # Defines the classes based on the wsdl document.
      # Assumes the following namespaces in the wsdl.
      # xmlns="http://schemas.xmlsoap.org/wsdl/" 
      # xmlns:http="http://schemas.xmlsoap.org/wsdl/http/" 
      # xmlns:xs="http://www.w3.org/2001/XMLSchema" 
      # xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
      # xmlns:zns="http://api.zuora.com/" 
      # xmlns:ons="http://object.api.zuora.com/"
      # xmlns:fns="http://fault.api.zuora.com/"
      @document.xpath('.//xs:schema[@targetNamespace]').each do |schema|
        namespace = schema.attribute("targetNamespace").value

        schema.xpath('.//xs:complexType[@name]').each do |complex_type|
          class_name = complex_type.attribute("name").value
          # Skip the zObject base class, we define our own.
          next if class_name == "zObject"
          
          zuora_class = Class.new
          @class_nesting.const_set(class_name, zuora_class)
          @classes << zuora_class

          # Include the Base module for adding fields.
          zuora_class.send :include, Base
          zuora_class.namespace = namespace

          # If it's a zObject, include that module as well.
          if complex_type.xpath(".//xs:extension[@base='ons:zObject']").any?
            zuora_class.send :include, ZObject
          end

          # Define the fields
          complex_type.xpath('.//xs:element[@name][@type]').each do |element|
            # attributes: name, type, nillable, minoccurs, maxoccurs
            zuora_name = element.attribute("name").value
            field_name = zuora_name.underscore
            field_type = element.attribute("type").value
            is_array = element_is_an_array?(element)

            case field_type
            when "string", "xs:string", "zns:ID", "xs:base64Binary"
              zuora_class.field field_name, :string, 
                :zuora_name => zuora_name, :array => is_array
            when "boolean", "xs:boolean"
              zuora_class.field field_name, :boolean, 
                :zuora_name => zuora_name, :array => is_array
            when "int", "short", "long", "xs:int"
              zuora_class.field field_name, :integer, 
                :zuora_name => zuora_name, :array => is_array
            when "decimal"
              zuora_class.field field_name, :decimal, 
                :zuora_name => zuora_name, :array => is_array
            when "dateTime"
              zuora_class.field field_name, :datetime, 
                :zuora_name => zuora_name, :array => is_array
            when /\A(zns:|ons:)/
              zuora_class.field field_name, :object, 
                :zuora_name => zuora_name, :array => is_array, 
                :class_name => "#{@class_nesting.name}::#{field_type.split(':').last}"
            else
              puts "Unkown field type: #{field_type}"
            end
          end # each element

        end # each complexType
      end # each schema

      add_obvious_associations
      add_extra_customizations
    end

    private

    def add_obvious_associations
      # When a zuora class has a field called InvoiceId, it's a safe
      # assuption that it references the an Invoice.
      # Build those associations automatically.
      @classes.each do |zuora_class|
        zuora_class.fields.each do |field|
          # If it looks like an Id field and the name
          # matches a generated ZObject class
          if match = field.zuora_name.match(/\A(.+?)Id\Z/)
            if zobject_class = zobject_class_with_name(match[1])
              # Add a belongs to relationship.
              zuora_class.belongs_to zobject_class.zuora_object_name.underscore
              # If the current class is also a ZObject, add a has_many
              # to the referenced class.
              if zuora_class < ZObject
                zobject_class.has_many zuora_class.zuora_object_name.underscore.pluralize
              end
            end
          end
        end
      end
    end

    def add_extra_customizations
      # We can't know everything from the wsdl, like which fields are
      # usable in queries.  This function does some final customizations
      # based on the existing Zuora documentation.
      # Also, it's possible classes customized here weren't defined
      # in your wsdl, so it will only customize them if they are defined.

      customize 'Account' do |zuora_class|
        zuora_class.belongs_to :parent, 
          :class_name => "#{@class_nesting.name}::Account"
        zuora_class.has_many :children, 
          :class_name => "#{@class_nesting.name}::Account", :foreign_key => :parent_id, :inverse_of => :parent
      end

      customize 'Amendment' do |zuora_class|
        zuora_class.exclude_from_queries :rate_plan_data, 
          :destination_account_id, :destination_invoice_owner_id  
      end

      customize 'Import' do |zuora_class|
        zuora_class.exclude_from_queries :file_content
      end

      customize 'InvoiceItemAdjustment' do |zuora_class|
        zuora_class.exclude_from_queries :customer_name, :customer_number
      end

      customize 'Payment' do |zuora_class|
        zuora_class.exclude_from_queries :applied_invoice_amount, 
          :gateway_option_data, :invoice_id, :invoice_number
      end

      customize 'PaymentMethod' do |zuora_class|
        zuora_class.exclude_from_queries :ach_account_number, :credit_card_number,
          :credit_card_security_code, :gateway_option_data, :skip_validation
      end

      customize 'ProductRatePlanCharge' do |zuora_class|
        zuora_class.exclude_from_queries :product_rate_plan_charge_tier_data
      end

      customize 'Usage' do |zuora_class|
        zuora_class.exclude_from_queries :ancestor_account_id, :invoice_id, :invoice_number
      end

      customize 'RatePlanCharge' do |zuora_class|
        zuora_class.exclude_from_queries :rollover_balance
        # Can only use overageprice or price or includedunits or 
        # discountamount or discountpercentage in one query.
        # We'll pick price.
        zuora_class.exclude_from_queries :overage_price, :included_units, 
          :discount_amount, :discount_percentage
      end

      customize 'Refund' do |zuora_class|
        zuora_class.exclude_from_queries :gateway_option_data, :payment_id
      end

      customize 'Subscription' do |zuora_class|
        zuora_class.exclude_from_queries :ancestor_account_id
      end

      customize 'SubscribeRequest' do |zuora_class|
        zuora_class.send :include, Subscribe
      end
    end

    def customize(zuora_class_name, &block)
      if @class_nesting.const_defined?(zuora_class_name)
        yield @class_nesting.const_get(zuora_class_name)
      end
    end

    def element_is_an_array?(element)
      attribute_is_more_than_one?(element.attribute("minOccurs")) ||
        attribute_is_more_than_one?(element.attribute("maxOccurs"))
    end

    def attribute_is_more_than_one?(attribute)
      attribute && ( attribute.value == "unbounded" || attribute.value.to_i > 1 )
    end

    def zobject_class_with_name(name)
      @classes.find { |zuora_class| zuora_class.zuora_object_name == name && zuora_class < ZObject }
    end

  end
end