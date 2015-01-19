require 'spec_helper'

describe 'Create Account' do

  integration_test do

    let(:account) do
      Z::Account.new name: 'Joe Customer',
                     currency: Tenant.currency,
                     bill_cycle_day: '1'
    end

    after(:each) do
      account.delete unless account.new_record?
    end

    it 'can create an account' do
      expect(account).to be_a_new_record
      expect(account).to_not be_valid
      expect(account.id).to_not be_present
      expect(account.errors.full_messages).to eq ["Status can't be blank"]

      now 'update account to be valid' do
        account.status = 'Draft'
        expect(account).to be_valid
        expect(account.errors.full_messages).to be_empty
      end

      now 'save the account' do
        expect(account.save).to be true
        expect(account.id).to be_present
        expect(account.errors.full_messages).to eq []
      end

      now 'ensure error messages are accessible' do
        expect(account.update_attributes status: 'Active').to be false
        expect(account.errors.full_messages).to eq ['Active account must have both sold to and bill to.']
      end
    end
  end
end
