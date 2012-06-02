require 'spec_helper'

describe "HasManyRelations" do

  integration_test do

    after do
      # Delete the account to cleanup in case a test failed.
      @account.delete if @account
    end

    it "can specify conditions" do

      @account = account = Z::Account.create!(
        :name => "ZObject Integration Test Account", 
        :status => "Draft",
        :currency => "USD", 
        :bill_cycle_day => 1)

      billy = Z::Contact.create!(
        :account => account,
        :first_name => "Billy",
        :last_name => "Blanks")

      franky = Z::Contact.create!(
        :account => account,
        :first_name => "Franky",
        :last_name => "Funhouse")

      @account.contacts.should =~ [billy, franky]

      Z::Account.instance_eval do
        has_many :billies, :conditions => { :first_name => "Billy" }, :class_name => 'Z::Contact'
      end

      @account.billies.should == [billy]

    end

  end
end