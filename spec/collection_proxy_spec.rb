require 'spec_helper'

describe "ActiveZuora::CollectionProxy" do

  it "should initialize" do
    cp = Z::CollectionProxy.new
    expect(cp).to be_empty
    cp = Z::CollectionProxy.new([Z::SubscribeRequest.new])
    expect(cp).not_to be_empty
  end

  it "should respond to enumerable methods" do
    cp = Z::CollectionProxy.new([Z::SubscribeRequest.new])
    cp.each do |cp|
      expect(cp)
    end
    cp.inject do |memo,cp|
      expect(memo)
      expect(cp)
    end
  end

  it "should respond to the batch_subscribe method" do
    cp = Z::CollectionProxy.new([Z::SubscribeRequest.new])
    expect(cp.respond_to?(:batch_subscribe)).to eq(true)
  end

end