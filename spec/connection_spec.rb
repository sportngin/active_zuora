require 'spec_helper'

describe ActiveZuora::Connection do
  context "custom header" do
    before do
      @connection = ActiveZuora::Connection.new
      @stub_was_called = false
    end

    it "passes the regular header if not set" do
      Savon::SOAP::Request.stub(:new) do |config, http, soap|
        @stub_was_called = true
        soap.header.should == {"SessionHeader" => {"session" => nil}}

        double('response').as_null_object
      end

      @connection.request(:amend) {}

      @stub_was_called.should eq true
    end

    it "merges in a custom header if set" do
      @connection.custom_header = {'CallOptions' => {'useSingleTransaction' => true}}
      Savon::SOAP::Request.stub(:new) do |config, http, soap|
        @stub_was_called = true
        soap.header.should == {"SessionHeader" => {"session" => nil}, 'CallOptions' => {'useSingleTransaction' => true}}

        double('response').as_null_object
      end

      @connection.request(:amend) {}

      @stub_was_called.should eq true
    end
  end
end
