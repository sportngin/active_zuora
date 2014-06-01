require 'spec_helper'

describe "HasManyRelations" do

  integration_test do

    before :all do
      @account = Z::Account.create!(
        :name => "ZObject Integration Test Account",
        :status => "Draft",
        :currency => Tenant.currency,
        :bill_cycle_day => 1)
      @billy = Z::Contact.create!(
        :account => @account,
        :first_name => "Billy",
        :last_name => "Blanks")
      @franky = Z::Contact.create!(
        :account => @account,
        :first_name => "Franky",
        :last_name => "Funhouse")
    end

    after :all do
      # Delete the account to cleanup in case a test failed.
      @account.delete if @account
    end

    it "can specify conditions and order" do
      Z::Account.instance_eval do
        has_many :billies, :conditions => { :first_name => "Billy" }, :order => [:first_name, :desc], :class_name => 'Z::Contact'
      end
			expect(@account.billies.to_a).to eq([@billy])
      expect(@account.billies.scope.order_attribute).to eq(:first_name)
      expect(@account.billies.scope.order_direction).to eq(:desc)
    end

    it "can behave like an array" do
      expect(@account.contacts.size).to eq(2)
      expect(@account.contacts.map(&:first_name)).to match_array(%w{Billy Franky})
    end

    it "can respond to functions on the Relation" do
      @account.contacts.unload
      expect(@account.contacts.loaded?).to be_falsey
      @account.contacts.reload
      expect(@account.contacts.loaded?).to be_truthy
      expect(@account.contacts.where(:last_name => "Funhouse").to_a).to eq([@franky])
      expect(@account.contacts.loaded?).to be_truthy
      expect(@account.contacts.to_a).to match_array([@billy, @franky])
    end

  end
end