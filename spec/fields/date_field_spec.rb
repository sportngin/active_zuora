require 'spec_helper'

describe ActiveZuora::DateField do
  subject { described_class.new("date", described_class, {:zuora_name => "date"}) }

  describe "#type_cast" do
    it "returns nil if provided nil" do
      expect(subject.type_cast(nil)).to eq(nil)
    end

    it "returns a date when given a datetime object" do
      datetime = DateTime.now
      expect(subject.type_cast(datetime)).to be_a(Date)
    end

    it "returns a date when given a date object" do
      date = Date.today
      expect(subject.type_cast(date)).to be_a(Date)
    end
  end

  describe "#build_xml" do
    let(:xml)  { double(:xml, :tag! => nil) }
    let(:soap) { double(:soap, :namespace_by_uri => nil) }
    let(:options) { {} }

    it "handles a nil value" do
      expect { subject.build_xml(xml, soap, nil, options) }.to_not raise_error
    end

    it "handles a date value" do
      expect { subject.build_xml(xml, soap, Date.today, options) }.to_not raise_error
    end
  end
end
