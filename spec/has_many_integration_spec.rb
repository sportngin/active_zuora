require 'spec_helper'

describe "HasManyRelations" do

  integration_test do

    before :all do
      @account = Z::Account.create!(
        :name => "ZObject Integration Test Account", 
        :status => "Draft",
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
      @account.billies.to_a == [@billy]
      @account.billies.scope.order_attribute.should == :first_name
      @account.billies.scope.order_direction.should == :desc
    end

    it "can behave like an array" do
      @account.contacts.size.should == 2
      @account.contacts.map(&:first_name).should =~ %w{Billy Franky}
    end

    it "can respond to functions on the Relation" do
      @account.contacts.unload
      @account.contacts.loaded?.should be_false
      @account.contacts.reload
      @account.contacts.loaded?.should be_true
      @account.contacts.where(:last_name => "Funhouse").to_a.should == [@franky]
      @account.contacts.loaded?.should be_true
      @account.contacts.to_a.should =~ [@billy, @franky]
    end

  end
end