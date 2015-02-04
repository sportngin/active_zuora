require 'spec_helper'

describe ActiveZuora::Base do
  class Comment
    include ActiveZuora::ZObject
    field :name, :string
    field :null_field, :string
  end

  context "#fields_order" do
    let(:comment) { Comment.new :id => 'blog1', :null_field => nil, :name => 'test' }
    let(:field_id) { comment.get_field(:id) }
    let(:field_null) { comment.get_field(:null_field) }
    let(:field_name) { comment.get_field(:name) }
    let(:sorted_fields) { [field_null, field_id, field_name] }

    it 'When the value of a field is null, it should be the first' do
      fields1 = [field_id, field_null]
      expect(fields1.sort(&comment.method(:fields_order))).to eq([field_null, field_id])

      fields2 = [field_name, field_null]
      expect(fields2.sort(&comment.method(:fields_order))).to eq([field_null, field_name])

      fields3 = [field_id, field_name, field_null]
      expect(fields3.sort(&comment.method(:fields_order))).to eq(sorted_fields)
    end

    it 'When the field name is id, it should be after the nil value fields but before all other fields' do
      fields1 = [field_name, field_id]
      expect(fields1.sort(&comment.method(:fields_order))).to eq([field_id, field_name])

      fields2 = [field_null, field_id]
      expect(fields2.sort(&comment.method(:fields_order))).to eq([field_null, field_id])

      fields3 = [field_name, field_id, field_null]
      expect(fields3.sort(&comment.method(:fields_order))).to eq(sorted_fields)
    end
  end
end
