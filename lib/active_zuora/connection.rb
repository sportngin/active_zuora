module ActiveZuora
  class Connection

    attr_reader :soap_client
    attr_accessor :custom_header

    WSDL = File.expand_path('../../../wsdl/zuora.wsdl', __FILE__)

    def initialize(configuration={})
      # Store login credentials and create SOAP client.
      @username = configuration[:username]
      @password = configuration[:password]
      @soap_client = Savon::Client.new do
        wsdl.document = configuration[:wsdl] || WSDL
        http.proxy = configuration[:http_proxy] if configuration[:http_proxy]
      end
    end

    def login
      # Returns a session_id upon success, raises an exception on failure.
      # Instance variables aren't available within the soap request block.
      body = { :username => @username, :password => @password }
      header = @custom_header
      @soap_client.request(:login) do
        soap.body = body
        soap.header = header
      end[:login_response][:result][:session]
    end

    def request(*args, &block)
      # instance variables aren't available within the soap request block for some reason.
      header = { 'SessionHeader' => { 'session' => @session_id } }
      header.merge!(@custom_header) if @custom_header

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

  end
end
