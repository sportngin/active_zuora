require 'spec_helper'

describe "Subscribe" do

  integration_test do

    before do
      # Setup product.
      @product = Z::Product.where(:name => "Awesome Product").first ||
        Z::Product.create!(
          :name => "Awesome Product",
          :features__c => "Now with even more awesome features!",
          :benefits__c => "Now with even more awesome benefits!",
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
              # :active => true, ### Depreciated as of WSDL 46
              :currency => Tenant.currency,
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
          :currency => Tenant.currency,
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
      expect(subscribe_request.account.new_record?).to be_falsey
      expect(subscribe_request.account.changed?).to be_falsey
      expect(subscribe_request.subscription_data.subscription.new_record?).to be_falsey
      expect(subscribe_request.subscription_data.subscription.rate_plans.first.
        rate_plan_charges.first.
        product_rate_plan_charge).to eq(@product_rate_plan_charge)
      expect(subscribe_request.result).to be_present

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
      expect(amend_request.amendments.first.new_record?).to be_falsey
      expect(amend_request.result).to be_present
    end

    it "Can successfully subscribe and generate an invoice" do

      subscribe_request = Z::SubscribeRequest.new(
        :account => {
          :name => "Joe Customer",
          :currency => Tenant.currency,
          :bill_cycle_day => 1,
          :payment_term => "Due Upon Receipt",
          :batch => "Batch1"
        },
        :payment_method => {
          :type => "CreditCard",
          :credit_card_holder_name => "Robert Paulson",
          :credit_card_type => "MasterCard",
          :credit_card_number => "4111111111111111",
          :credit_card_expiration_month => (sprintf '%02d', Date.today.month),
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
            :contract_effective_date => DateTime.now,
            :service_activation_date => DateTime.now,
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
      expect(subscribe_request.account.new_record?).to be_falsey
      expect(subscribe_request.account.changed?).to be_falsey
      expect(subscribe_request.subscription_data.subscription.new_record?).to be_falsey
      expect(subscribe_request.subscription_data.subscription.rate_plans.first.
        rate_plan_charges.first.
        product_rate_plan_charge).to eq(@product_rate_plan_charge)
      expect(subscribe_request.result).to be_present

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
      expect(amend_request.amendments.first.new_record?).to be_falsey
      expect(amend_request.result).to be_present

      invoice = Z::Invoice.new(
          account_id: subscribe_request.account.id,
          invoice_date: Date.today,
          target_date: Date.today + 12.months,
          includes_one_time: false,
          includes_recurring: true,
          includes_usage: false
      )
      invoice.generate!
      expect(invoice.id).to be_present
      expect(invoice.account_id).to eq(subscribe_request.account.id)
    end

  end
end
