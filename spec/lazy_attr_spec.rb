require 'spec_helper'

describe 'LazyAttr' do
  class TestInovice
    include ActiveZuora::LazyAttr
    lazy_load :test_body
  end

  subject { TestInovice.new }

  it "should fetch a lazy loaded attribute from the api" do
    expect(subject).to receive(:fetch_field).with(:test_body){ 'Jesse "The Body"' }
    subject.test_body
  end

  it "should should not refetch an attribute after it's been loaded once" do
    expect(subject).to receive(:fetch_field).with(:test_body).once { 'Jesse "The Body"' }
    subject.test_body
    subject.test_body
  end

end
