require 'spec_helper'

describe "Subscribe" do

  before do
    # Setup product.
    @product = Z::Product.where(:name => "Awesome Product").first || 
      Z::Product.create!(
        :name => "Awesome Product",
        :effective_start_date => Date.today,
        :effective_end_date => Date.tomorrow
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
            :currency => "USD",
            :tier => 1,
            :price => 50.00,
            :starting_unit => 1,
            :ending_unit => 1000
          }
        }
      )
  end

  after do
    @account.delete if @account
    @product.delete
  end

  it "Can successfully subscribe using a new account" do

    subscribe_request = Z::SubscribeRequest.new(
      :account => {
        :name => "Joe Customer",
        :currency => "USD",
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
        :work_email => "conny.client@example.com"
      },
      :subscription_data => {
        :subscription => {},
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
        },
      }
    )

    subscribe_request.subscribe!
    @account = Z::Account.find(subscribe_request.result[:account_id])
    @account.should_not be_nil
    @account.subscriptions.first.rate_plans.first.rate_plan_charges.first.
      product_rate_plan_charge.should == @product_rate_plan_charge

  end

end