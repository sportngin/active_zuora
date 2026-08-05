require 'spec_helper'

describe ActiveZuora::Relation do
  describe '#query' do
    it 'adds the ZQL to SOAP fault messages' do
      field = double('field', :zuora_name => 'Id')
      connection = double('connection')
      zobject_class = double(
        'zobject_class',
        :connection => connection,
        :current_scope => nil,
        :current_scope= => nil,
        :field? => false,
        :get_field! => field,
        :zuora_object_name => 'Account'
      )
      relation = described_class.new(zobject_class)
      fault = Savon::SOAPFault.allocate

      def fault.to_s
        'original fault'.dup
      end

      expect(connection).to receive(:request).with(:query).and_raise(fault)

      expect { relation.query }.
        to raise_error(Savon::SOAPFault, 'original fault: select Id from Account ')
    end
  end
end
