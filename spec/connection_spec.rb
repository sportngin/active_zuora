require 'spec_helper'

describe ActiveZuora::Connection do
  context "custom header" do
    before do
      @connection = ActiveZuora::Connection.new
      @stub_was_called = false
    end

    it "passes the regular header if not set" do
      response = double('response', :body => {})
      expect(@connection.soap_client).to receive(:call).
        with(:amend, hash_including(:soap_header => { "SessionHeader" => {"session" => nil} })).
        and_return(response)

      @connection.request(:amend) {}
    end

    it "merges in a custom header if set" do
      @connection.custom_header = {'CallOptions' => {'useSingleTransaction' => true}}
      response = double('response', :body => {})
      expect(@connection.soap_client).to receive(:call).
        with(:amend, hash_including(:soap_header => { "SessionHeader" => {"session" => nil}, 'CallOptions' => {'useSingleTransaction' => true} })).
        and_return(response)

      @connection.request(:amend) {}
    end
  end

  describe 'login' do
    before do
      @connection = described_class.new
    end

    context 'when a custom header is set' do
      it 'uses the custom header' do
        @connection.custom_header = { 'TestHeader' => 'Foo' }
        response = double('response', :body => { :login_response => { :result => { :session => 'session' } } })
        expect(@connection.soap_client).to receive(:call).
          with(:login, :message => { :username => nil, :password => nil }, :soap_header => { 'TestHeader' => 'Foo' }).
          and_return(response)

        @connection.login
      end
    end

    context 'when a custom header is not set' do
      it 'does not use the custom header' do
        response = double('response', :body => { :login_response => { :result => { :session => 'session' } } })
        expect(@connection.soap_client).to receive(:call).
          with(:login, :message => { :username => nil, :password => nil }, :soap_header => {}).
          and_return(response)

        @connection.login
      end
    end
  end
end
