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

    def start_session
      # instance variables aren't available within the soap request block for some reason.
      body = { :username => @username, :password => @password }
      response = @soap_client.request(:login) do
        soap.body = body
      end
      if response.success?
        @session_expires_at = Time.now + @session_timeout
        @session_id = response.to_hash[:login_response][:result][:session]
      end
      response
    end

    def session_expired?
      @session_id.nil? || @session_expires_at <= Time.now
    end

    def request *args
      # Login if we know ahead of time that our session has timed out.
      if session_expired?
        start_session_response = start_session
        # Return the error response if the start_session failed.
        return start_session_response.to_hash unless start_session_response.success?
      end
      # instance variables aren't available within the soap request block for some reason.
      header = { 'SessionHeader' => { 'session' => @session_id } }
      response = @soap_client.request(*args) do
        soap.header = header
        yield(soap)
      end.to_hash
      # Check for an invalid(expired) session response.  Delete the session id and try again.
      if response[:fault] && response[:fault][:faultcode] == 'fns:INVALID_SESSION'
        @session_id = nil
        request action, body
      else
        response
      end
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
    end

  end

end