module ActiveZuora
  class Connection

    attr_reader :soap_client

    WSDL = File.expand_path('../../../wsdl/zuora.wsdl', __FILE__)

    def initialize(configuration={})
      # Store login credentials and create SOAP client.
      @username = configuration[:username]
      @password = configuration[:password]
      @session_timeout = configuration[:session_timeout] || 15.minutes
      @soap_client = Savon::Client.new do
        wsdl.document = configuration[:wsdl] || WSDL
      end
    end

    def login
      # Returns a session_id upon success, raises an exception on failure.
      # Instance variables aren't available within the soap request block.
      body = { :username => @username, :password => @password }
      @soap_client.request(:login){ soap.body = body }[:login_response][:result][:session]
    end

    def request(*args, &block)
      # instance variables aren't available within the soap request block for some reason.
      header = { 'SessionHeader' => { 'session' => @session_id } }
      @soap_client.request(*args) do
        soap.header = header
        yield(soap)
      end
    rescue Savon::SOAP::Fault => exception
      # Catch invalid sessions, and re-issue the request.
      raise unless exception.message =~ /INVALID_SESSION/
      @session_id = login
      request(*args, &block)
    end

    def query zql
      # Keep querying until all pages are retrieved.
      # Throws an exception for an invalid query.
      response = request(:query){ |soap| soap.body = { :query_string => zql } }
      query_response = response[:query_response]
      records = query_response[:result][:records] || []
      # Sometimes Zuora will return only a single record, not in an array.
      records = [records] unless records.is_a?(Array)
      # If there are more pages of records, keep fetching
      # them until done.
      until query_response[:result][:done]
        query_response = request(:query_more) do |soap|
          soap.body = { :query_locator => response[:query_response][:result][:query_locator] }
        end[:query_more_response]
        records.concat query_response[:result][:records]
      end
      # Strip any noisy attributes from the results that have to do with 
      # SOAP namespaces.
      records.each do |record|
        record.delete_if { |key, value| key.to_s.start_with? "@" }
      end
      records
    rescue Savon::SOAP::Fault => exception
      # Add the zql to the exception message and re-raise.
      exception.message << ": #{zql}"
      raise
    end

  end
end