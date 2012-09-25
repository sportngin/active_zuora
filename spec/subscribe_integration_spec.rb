require 'spec_helper'

describe "Subscribe" do

  integration_test do

    before do
      # Setup product.
      @product = Z::Product.where(:name => "Awesome Product").first || 
        Z::Product.create!(
          :name => "Awesome Product",
          :effective_start_date => Date.today,
          :effective_end_date => Date.today + 10.years
        )
      @product_rate_plan = @product.product_rate_plans.first ||
        Z::ProductRatePlan.create!(
          :product => @product,
          :name => "Awesome Plan"
        )
      @product_rate_plan_charge = @product_rate_plan.product_rate_plan_charges.first ||
        Z::ProductRatePlanCharge.create!(
          :product_rate_plan => @product_rate_plan,
          :name => "Monthly Service",
          :charge_model => "Flat Fee Pricing",
          :charge_type => "Recurring",
          :billing_period => "Month",
          :trigger_event => "ContractEffective",
          :product_rate_plan_charge_tier_data => {
            :product_rate_plan_charge_tier => {
              :active => true,
              :currency => "AUD",
              :tier => 1,
              :price => 50.00,
              :starting_unit => 1,
              :ending_unit => 1000
            }
          }
        )
    end

    after do
      @account.delete
      @product.delete
    end

    it "Can successfully subscribe and amend using a new account" do

      subscribe_request = Z::SubscribeRequest.new(
        :account => {
          :name => "Joe Customer",
          :currency => "AUD",
          :bill_cycle_day => 1,
          :payment_term => "Due Upon Receipt",
          :batch => "Batch1"
        },
        :payment_method => {
          :type => "CreditCard",
          :credit_card_holder_name => "Robert Paulson",
          :credit_card_type => "MasterCard",
          :credit_card_number => "5424000000000015",
          :credit_card_expiration_month => 1,
          :credit_card_expiration_year => (Date.today.year + 1)
        },
        :bill_to_contact => { 
          :first_name => "Conny",
          :last_name => "Client",
          :country => "AU",
          :work_email => "conny.client@example.com"
        },
        :subscription_data => {
          :subscription => {
            :contract_effective_date => Date.today,
            :service_activation_date => Date.today,
            :initial_term => 12,
            :renewal_term => 12
          },
          :rate_plan_data => {
            :rate_plan => {
              :product_rate_plan_id => @product_rate_plan.id,
            },
            :rate_plan_charge_data => {
              :rate_plan_charge => {
                :product_rate_plan_charge_id => @product_rate_plan_charge.id,
                :price => 45.00
              }
            }
          }
        }
      )

      subscribe_request.subscribe!
      @account = subscribe_request.account
      subscribe_request.account.new_record?.should be_false
      subscribe_request.account.changed?.should be_false
      subscribe_request.subscription_data.subscription.new_record?.should be_false
      subscribe_request.subscription_data.subscription.rate_plans.first.
        rate_plan_charges.first.
        product_rate_plan_charge.should == @product_rate_plan_charge
      subscribe_request.result.should be_present

      # Now amend the subscription
      subscription = subscribe_request.subscription_data.subscription.reload
      amend_request = Z::AmendRequest.new(
        :amendments => {
          :name => "Remove Awesome Plan",
          :contract_effective_date => Date.today,
          :service_activation_date => Date.today,
          :subscription_id => subscription.id,
          :type => "RemoveProduct",
          :rate_plan_data => {
            :rate_plan => {
              :amendment_subscription_rate_plan_id => subscription.rate_plans.first.id
            }
          }
        },
        :amend_options => {
          :generate_invoice => false,
          :process_payments => false
        }
      ) 
      amend_request.amend!
      amend_request.amendments.first.new_record?.should be_false
      amend_request.result.should be_present
    end

    it "Can successfully subscribe and generate an invoice" do

      subscribe_request = Z::SubscribeRequest.new(
        :account => {
          :name => "Joe Customer",
          :currency => "AUD",
          :bill_cycle_day => 1,
          :payment_term => "Due Upon Receipt",
          :batch => "Batch1"
        },
        :payment_method => {
          :type => "CreditCard",
          :credit_card_holder_name => "Robert Paulson",
          :credit_card_type => "MasterCard",
          :credit_card_number => "4111111111111111",
          :credit_card_expiration_month => 1,
          :credit_card_expiration_year => (Date.today.year + 1)
        },
        :bill_to_contact => { 
          :first_name => "Conny",
          :last_name => "Client",
          :work_email => "conny.client@example.com",
          :country => "AU"
        },
        :subscription_data => {
          :subscription => {
            :contract_effective_date => Date.today,
            :service_activation_date => Date.today,
            :initial_term => 12,
            :renewal_term => 12,
            :term_type => 'TERMED'
          },
          :rate_plan_data => {
            :rate_plan => {
              :product_rate_plan_id => @product_rate_plan.id,
            },
            :rate_plan_charge_data => {
              :rate_plan_charge => {
                :product_rate_plan_charge_id => @product_rate_plan_charge.id,
                :price => 45.00
              }
            }
          }
        }
      )

      subscribe_request.subscribe!
      @account = subscribe_request.account
      subscribe_request.account.new_record?.should be_false
      subscribe_request.account.changed?.should be_false
      subscribe_request.subscription_data.subscription.new_record?.should be_false
      subscribe_request.subscription_data.subscription.rate_plans.first.
        rate_plan_charges.first.
        product_rate_plan_charge.should == @product_rate_plan_charge
      subscribe_request.result.should be_present

      # Now renew the subscription
      subscription = subscribe_request.subscription_data.subscription.reload

      amend_request = Z::AmendRequest.new(
        :amendments => {
          :name => "Renew",
          :contract_effective_date => Date.today + 12.months,
          :effective_date => Date.today,
          :subscription_id => subscription.id,
          :type => "Renewal",
          :auto_renew => false,
          :renewal_term => 12
        },
        :amend_options => {
          :generate_invoice => false,
          :process_payments => false
        }
      )
      amend_request.amend!
      amend_request.amendments.first.new_record?.should be_false
      amend_request.result.should be_present

      invoice = Z::Invoice.new(
          account_id: subscribe_request.account.id,
          invoice_date: Date.today,
          target_date: Date.today + 12.months,
          includes_one_time: false,
          includes_recurring: true,
          includes_usage: false
      )
      invoice.generate!
      invoice.id.should be_present
      invoice.account_id.should == subscribe_request.account.id
    end

  end
end
