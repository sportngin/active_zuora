require 'spec_helper'

describe "ZObject" do

  integration_test do

    after do
      # Delete the account to cleanup in case a test failed.
      @account.delete if @account
    end

    it "can can be created, queried, updated, and destroyed" do

      # Test failed creation.
      @account = Z::Account.create
      @account.new_record?.should be_true
      @account.errors.should be_present

      # Test creation.
      @account = Z::Account.new(
        :name => "ZObject Integration Test Account", 
        :currency => "USD", 
        :status => "Draft", 
        :bill_cycle_day => 1)
      @account.changes.should be_present
      @account.save.should be_true
      @account.new_record?.should be_false
      @account.errors.should be_blank
      @account.changes.should be_blank

      # Test update.
      @account.name = "ZObject Integration Test Account 2"
      @account.changes.should be_present
      @account.save.should be_true
      @account.changes.should be_blank

      # Test querying.
      Z::Account.where(:name => "Some Random Name").all.should_not include(@account)
      Z::Account.where(:name => "Some Random Name").or(:name => @account.name).all.should include(@account)

      # Update all.
      Z::Account.where(:name => @account.name).update_all(:name => "ZObject Integration Test Account 3").should == 1
      @account.reload.name.should == "ZObject Integration Test Account 3"
      # Block-style update_all
      Z::Account.where(:name => @account.name).update_all { |account| account.name += "4" }.should == 1
      @account.reload.name.should == "ZObject Integration Test Account 34"
      # No changes, so no records were updated.
      Z::Account.where(:name => @account.name).update_all(:name => "ZObject Integration Test Account 34").should == 0

      # Delete all
      Z::Account.where(:name => @account.name).delete_all.should == 1
      @account = nil

    end

  end
end