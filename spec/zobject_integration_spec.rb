require 'spec_helper'

describe "ZObject" do

  integration_test do

    after do
      # Delete the account to cleanup in case a test failed.
      @account.delete if @account
      @child.delete if @child
    end

    it "can be created, queried, updated, and destroyed" do

      # Test failed creation.
      @account = Z::Account.create
      expect(@account.new_record?).to be_truthy
      expect(@account.errors).to be_present

      # Test creation.
      @account = Z::Account.new(
        :name => "ZObject Integration Test Account",
        :currency => Tenant.currency,
        :status => "Draft",
        :bill_cycle_day => 1)
      expect(@account.changes).to be_present
      expect(@account.save).to be_truthy
      expect(@account.new_record?).to be_falsey
      expect(@account.errors).to be_blank
      expect(@account.changes).to be_blank

      # Test update.
      @account.name = "ZObject Integration Test Account 2"
      expect(@account.changes).to be_present
      expect(@account.save).to be_truthy
      expect(@account.changes).to be_blank

      # Test querying.
      expect(Z::Account.where(:name => "Some Random Name").all.to_a).to_not include(@account)
      expect(Z::Account.where(:name => "Some Random Name").or(:name => @account.name).all.to_a).to include(@account)
      expect(Z::Account.where(:created_date => { ">=" => Date.yesterday }).all.to_a).to include(@account)
      expect(Z::Account.where(:created_date => { ">" => Time.now }).or(:name => @account.name).all.to_a).to include(@account)
      Z::Account.where(:created_date => { ">=" => Date.today }).find_each do |account|
        expect(account).to be_present
      end

      # Test ordering
      unordered = Z::Account.where(:created_date => { ">=" => Date.today })
      ordered = unordered.order(:name, :desc)
      expect(unordered.order_attribute).to eq(:created_date)
      expect(unordered.order_direction).to eq(:asc)
      expect(ordered.order_attribute).to eq(:name)
      expect(ordered.order_direction).to eq(:desc)

      # Test scopes and chaining.
      Z::Account.instance_eval do
        scope :draft, :status => "Draft"
        scope :active, where(:status => "Active")
        scope :since, lambda { |datetime| where(:created_date => { ">=" => datetime }) }
      end
      expect(Z::Account.select(:id).draft.to_zql).to eq("select Id from Account where Status = 'Draft'")
      expect(Z::Account.select(:id).active.since(Date.new 2012).to_zql).to eq("select Id from Account where Status = 'Active' and CreatedDate >= '2012-01-01T00:00:00+08:00'")

      # Update all.
      expect(Z::Account.where(:name => @account.name).update_all(:name => "ZObject Integration Test Account 3")).to eq(1)
      expect(@account.reload.name).to eq("ZObject Integration Test Account 3")
      # Block-style update_all
      expect(Z::Account.where(:name => @account.name).update_all { |account| account.name += "4" }).to eq(1)
      expect(@account.reload.name).to eq("ZObject Integration Test Account 34")
      # No changes, so no records were updated.
      expect(Z::Account.where(:name => @account.name).update_all(:name => "ZObject Integration Test Account 34")).to eq(0)

      # Associations
      @child = Z::Account.create!(
        :parent_id => @account.id,
        :name => "ZObject Integration Test Child Account",
        :currency => Tenant.currency,
        :status => "Draft",
        :bill_cycle_day => 1)
      expect(@account.children.to_a).to include(@child)
      expect(@child.parent).to eq(@account)
      # Make sure that the has_many pre-loads the inverse relationship.
      @account.children.each { |child| expect(child.parent_loaded?).to be_truthy }

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
      expect(Z::Account.save(batch_accounts)).to eq(batch_number)

      # Delete all
      expect(Z::Account.where(:name => @account.name).delete_all).to be >= 1
      @account = nil

    end

  end
end
