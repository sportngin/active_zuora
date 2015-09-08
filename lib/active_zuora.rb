require 'savon'
require 'active_model'
require 'active_support/all'

require 'active_zuora/connection'
require 'active_zuora/generator'
require 'active_zuora/fields'
require 'active_zuora/belongs_to_associations'
require 'active_zuora/base'
require 'active_zuora/relation'
require 'active_zuora/scoping'
require 'active_zuora/persistence'
require 'active_zuora/has_many_proxy'
require 'active_zuora/has_many_associations'
require 'active_zuora/z_object'
require 'active_zuora/subscribe'
require 'active_zuora/amend'
require 'active_zuora/generate'
require 'active_zuora/billing_preview'
require 'active_zuora/batch_subscribe'
require 'active_zuora/collection_proxy'

module ActiveZuora

  # Setup configuration.  None of this sends a request.
  def self.configure(configuration)
    # Set some sensible defaults with the savon SOAP client.
    Savon.configure do |config|
      config.log = HTTPI.log = configuration[:log] || false
      config.log_level = configuration[:log_level] || :info
      config.logger = configuration[:logger] if configuration[:logger]
      config.logger.filter = configuration[:log_filters] || [:password, :SessionHeader]
      config.raise_errors = true
    end
    # Create a default connection on Base
    Base.connection = Connection.new(configuration)
  end

  def self.generate_classes(options={})
    generator = Generator.new(Base.connection.soap_client.wsdl.parser, options)
    generator.generate_classes
  end

end
