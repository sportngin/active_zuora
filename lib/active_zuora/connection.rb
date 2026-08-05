require 'builder'

module ActiveZuora
  class Connection

    attr_reader :soap_client
    attr_accessor :custom_header

    WSDL = File.expand_path('../../../wsdl/zuora.wsdl', __FILE__)

    class SoapRequest
      BODY_NOT_PROVIDED = Object.new

      class NamespacedXmlBuilder
        BUILDER_METHODS = (
          ::Builder::XmlBase.public_instance_methods(false) +
          ::Builder::XmlMarkup.public_instance_methods(false)
        ).freeze

        def initialize
          @builder = ::Builder::XmlMarkup.new
        end

        BUILDER_METHODS.each do |method_name|
          next if method_name == :method_missing

          define_method(method_name) do |*args, &block|
            @builder.__send__(method_name, *args, &wrap_block(block))
          end
        end

        private

        def wrap_block(block)
          return unless block

          proc do
            block.arity.positive? ? block.call(self) : block.call
          end
        end

        def method_missing(method, *args, &block)
          @builder.tag!(method, *args, &wrap_block(block))
        end

        def respond_to_missing?(method, include_private = false)
          true
        end
      end

      attr_accessor :header
      attr_reader :body

      def initialize(connection)
        @connection = connection
        @header = {}
        @body = nil
      end

      def body(value = BODY_NOT_PROVIDED)
        return @body if value.equal?(BODY_NOT_PROVIDED) && !block_given?

        if block_given?
          xml = NamespacedXmlBuilder.new
          yield xml
          @body = xml.target!
        else
          @body = value
        end
      end

      def body=(value)
        @body = value
      end

      def namespace
        @connection.soap_client.wsdl.namespace
      end

      def namespace_by_uri(uri)
        namespace = @connection.soap_client.wsdl.parser.document.namespaces.key(uri)
        namespace&.sub(/\Axmlns:/, '')
      end
    end

    def initialize(configuration={})
      # Store login credentials and create SOAP client.
      @username = configuration[:username]
      @password = configuration[:password]
      @soap_client = Savon::Client.new(client_options(configuration))
    end

    def login
      # Returns a session_id upon success, raises an exception on failure.
      # Instance variables aren't available within the soap request block.
      body = { :username => @username, :password => @password }
      header = @custom_header
      response = @soap_client.call(:login, :message => body, :soap_header => header || {})
      response.body[:login_response][:result][:session]
    end

    def request(*args, &block)
      # instance variables aren't available within the soap request block for some reason.
      header = { 'SessionHeader' => { 'session' => @session_id } }
      header.merge!(@custom_header) if @custom_header

      soap = SoapRequest.new(self)
      soap.header = header
      yield(soap)

      response = @soap_client.call(args.first, :message => (soap.body || {}), :soap_header => soap.header)
      response.define_singleton_method(:[]) { |key| body[key] } unless response.respond_to?(:[])
      response
    rescue Savon::SOAPFault => exception
      # Catch invalid sessions, and re-issue the request.
      raise unless exception.message =~ /INVALID_SESSION/
      @session_id = login
      request(*args, &block)
    end

    private def client_options(configuration)
      options = {
        :wsdl => configuration[:wsdl] || WSDL,
        :log => configuration[:log] || false,
        :log_level => configuration[:log_level] || :info,
        :filters => configuration[:log_filters] || [:password, :SessionHeader],
        :raise_errors => true
      }
      options[:logger] = configuration[:logger] if configuration[:logger]
      options[:pretty_print_xml] = configuration[:pretty_print_xml] if configuration.key?(:pretty_print_xml)
      options[:proxy] = configuration[:http_proxy] if configuration[:http_proxy]
      options
    end

  end
end
