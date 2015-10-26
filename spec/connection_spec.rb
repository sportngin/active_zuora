require 'spec_helper'

describe ActiveZuora::Connection do
  context "custom header" do
    before do
      @connection = ActiveZuora::Connection.new
      @stub_was_called = false
    end

    it "passes the regular header if not set" do
      allow(Savon::SOAP::Request).to receive(:new) do |config, http, soap|
        @stub_was_called = true
        expect(soap.header).to eq( { "SessionHeader" => {"session" => nil} } )

        double('response').as_null_object
      end

      @connection.request(:amend) {}

      expect(@stub_was_called).to be_truthy
    end

    it "merges in a custom header if set" do
      @connection.custom_header = {'CallOptions' => {'useSingleTransaction' => true}}
      allow(Savon::SOAP::Request).to receive(:new) do |config, http, soap|
        @stub_was_called = true
        expect(soap.header).to eq( { "SessionHeader" => {"session" => nil}, 'CallOptions' => {'useSingleTransaction' => true} } )

        double('response').as_null_object
      end

      @connection.request(:amend) {}

      expect(@stub_was_called).to be_truthy
    end
  end

  describe 'login' do
    before do
      @connection = described_class.new
    end

    context 'when a custom header is set' do
      it 'uses the custom header' do
        @connection.custom_header = { 'TestHeader' => 'Foo' }
        allow(Savon::SOAP::Request).to receive(:new) do |config, http, soap|
          expect(soap.header).to eq({ 'TestHeader' => 'Foo' })
          double('response').as_null_object
        end

        @connection.login
      end
    end

    context 'when a custom header is not set' do
      it 'does not use the custom header' do
        allow(Savon::SOAP::Request).to receive(:new) do |config, http, soap|
          expect(soap.header).to eq({})
          double('response').as_null_object
        end

        @connection.login
      end
    end
  end
end
