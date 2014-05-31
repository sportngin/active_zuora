require 'spec_helper'

describe "ZObject" do

  integration_test do

    after do
      # Delete the account to cleanup in case a test failed.
      @account.delete if @account
      @child.delete if @child
    end

    it "can can be created, queried, updated, and destroyed" do

      # Test failed creation.
      @account = Z::Account.create
      @account.new_record?.should be_true
      @account.errors.should be_present

      # Test creation.
      @account = Z::Account.new(
        :name => "ZObject Integration Test Account", 
        :status => "Draft", 
        :currency => Tenant.currency,
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
      Z::Account.where(:name => "Some Random Name").should_not include(@account)
      Z::Account.where(:name => "Some Random Name").or(:name => @account.name).should include(@account)
      Z::Account.where(:created_date => { ">=" => Date.today }).should include(@account)
      Z::Account.where(:created_date => { ">" => Time.now }).or(:name => @account.name).should include(@account)
      Z::Account.where(:created_date => { ">=" => Date.today }).find_each do |account|
        account.should be_present
      end

      # Test ordering
      unordered = Z::Account.where(:created_date => { ">=" => Date.today })
      ordered = unordered.order(:name, :desc)
      unordered.order_attribute.should == :created_date
      unordered.order_direction.should == :asc
      ordered.order_attribute.should == :name
      ordered.order_direction.should == :desc

      # Test scopes and chaining.
      Z::Account.instance_eval do
        scope :draft, :status => "Draft"
        scope :active, where(:status => "Active")
        scope :since, lambda { |datetime| where(:created_date => { ">=" => datetime }) }
      end
      Z::Account.select(:id).draft.to_zql.should == "select Id from Account where Status = 'Draft'"
      Z::Account.select(:id).active.since(Date.new 2012).to_zql.should == "select Id from Account where Status = 'Active' and CreatedDate >= '2012-01-01T00:00:00+08:00'"

      # Update all.
      Z::Account.where(:name => @account.name).update_all(:name => "ZObject Integration Test Account 3").should == 1
      @account.reload.name.should == "ZObject Integration Test Account 3"
      # Block-style update_all
      Z::Account.where(:name => @account.name).update_all { |account| account.name += "4" }.should == 1
      @account.reload.name.should == "ZObject Integration Test Account 34"
      # No changes, so no records were updated.
      Z::Account.where(:name => @account.name).update_all(:name => "ZObject Integration Test Account 34").should == 0

      # Associations
      @child = Z::Account.create!(
        :parent_id => @account.id,
        :name => "ZObject Integration Test Child Account", 
        :status => "Draft", 
        :currency => Tenant.currency,
        :bill_cycle_day => 1)
      @child.parent.should == @account
      @account.children.should include(@child)
      # Make sure that the has_many pre-loads the inverse relationship.
      @account.children.each { |child| child.parent_loaded?.should be_true }

      # Testing batch creates
      batch_accounts = []
      batch_number = 55
      (1..batch_number).each do |i|
        batch_accounts << Z::Account.new(
          :name => @account.name,
          :currency => Tenant.currency,
          :status => "Draft",
          :bill_cycle_day => 1)
      end
      Z::Account.save(batch_accounts).should == batch_number

      # Delete all
      Z::Account.where(:name => @account.name).delete_all.should >= 1
      @account = nil

    end

  end
end
