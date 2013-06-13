# active_zuora - Auto-Generated ActiveModel Interface for Zuora

[![TravisCI](https://secure.travis-ci.org/sportngin/active_zuora.png "TravisCI")](http://travis-ci.org/sportngin/active_zuora "Travis-CI ActiveZuora") [![Code Climate](https://codeclimate.com/github/sportngin/active_zuora.png)](https://codeclimate.com/github/sportngin/active_zuora)

Use Zuora's API like ActiveRecord.  Auto-generate all the classes from the wsdl file, or easily declare your own.

## Active Zuora Version 1
This repostiory contains >= Version 2 of Active Zuora

Version 1 can be found at https://github.com/sportngin/active_zuora_v1

## Configuration

    ActiveZuora.configure(
      :username => 'user@example.com',
      :password => 'password'
    )

Enable SOAP logging to stderr or provide your own wsdl file.

    ActiveZuora.configure(
      :username => 'user@example.com',
      :password => 'password',
      :log => true,
      :wsdl => 'path/to/zuora.wsdl'
    )

## Defining Classes

You can auto-generate all your Zuora classes from the wsdl file.  It will generate all Z-Objects, like Account and Subscription, and Zuora Complex objects, such as SubscribeRequest.

    ActiveZuora.generate_classes

By default, it will generate the classes inside the ActiveZuora module.  But you can specify a different nesting if you'd like.

    ActiveZuora.generate_classes :under => SomeOtherModule

Or, if you prefer, you can define your ZObjects or Complex Types manually.

    class Account

      include ActiveZuora::ZObject

      field :name, :string
      field :auto_pay, :boolean, :default => true
      field :balance, :decimal
      field :created_date, :datetime

      has_many :subscriptions, :order => :name
      has_many :active_subscriptions, :class_name => 'Subscription',
        :conditions => { :status => 'Active' },
        :order => [ :name, :desc ]
      belongs_to :parent, :class_name => 'Account'
      has_many :children, :class_name => 'Account', :foreign_key => :parent_id, :inverse_of => :parent

      validates_presence_of :name

    end

    class SubscriptionData

      include ActiveZuora::Base

      field :subscription, :object
      field :rate_plan_data, :object, :array => true

    end

## Saving, Updating, and Deleting

These familiar functions are available: save, create, and update_attributes, along with ! versions that raise exceptions upon failure.

    account = ActiveZuora::Account.new :name => "Frank's Pest Control"
    account.new_record?
    account.save

    account = ActiveZuora::Account.create! :name => "Frank's Pest Control"
    account.update_attributes :auto_pay => false, :currency => "USD"

Changes are also tracked.

    account = ActiveZuora::Account.new :name => "Frank's Pest Control"
    account.changes # { :name => [nil, "Frank's Pest Control"] }
    account.save!
    account.changes # []

Errors are captured using ActiveModel::Validations, or from error messages received from the server.

    account = ActiveZuora::Account.new
    account.save # false
    account.errors # { :base => ["Missing attribute: Name"] } # Returned from server.

Delete a record with #delete.

    account.delete

## Querying

    ActiveZuora::Account.find(id)

    ActiveZuora::Account.where(:name => "Frank's Pest Control").all

    ActiveZuora::Account.where(:name => { :like => '%Pest Control' }).count

    ActiveZuora::Account.where(:auto_pay => true).or(:balance => 0).all

    ActiveZuora::Account.select(:id, :name).where(:created_date => { "<" => Date.yesterday })

There is no "order by" clause in the ZQL query language, but ActiveZuora's query system can post-sort results for you:

    ActiveZuora::Account.where(:status => "Active").order(:name)

    ActiveZuora::Account.where(:status => "Draft").order(:created_date, :desc)

By default, every Query object caches the results once you call an array-like method on it.  However, if you know you'll have a very large result set and you just want to iterate through them without keeping them, you can use `find_each`.

    ActiveZuora::Account.where(:status => "Active").find_each do |account|
      ...
    end

## Scopes

    ActiveZuora::Account.instance_eval do
      scope :active, :status => "Active"
      scope :draft, where(:status => "Draft")
      scope :since, lambda { |datetime| where(:created_date => { ">=" => datetime }) }
    end

    ActiveZuora::Account.select(:id).draft.since(Date.new 2012).to_zql
    # => "select Id from Account where Status = 'Draft' and CreatedDate >= '2012-01-01T00:00:00+08:00'"

Like ActiveRecord, you can also chain any class method on the ZObject, since named scopes are nothing more than class methods that return a Relation object.

## Update or Delete Using Queries

You can update or delete multiple records at once.  The following command issues two requests to the Zuora API server: the first to query for the records, and the second to update them all at once.  The method returns the count of records that were successfully updated.

    ActiveZuora::Account.where(:status => "Draft").update_all :status => "Active" # 56

You can also use a block to update your records, in case your updates depend on the records themselves.

    ActiveZuora::Account.where(:status => "Draft").update_all do |account|
      account.name += " (#{account.currency})"
    end

You can also delete all records matching a query as well.  The method returns the amount of records deleted.

    ActiveZuora::Account.where(:status => "Draft").delete_all # 56

## License

Active Zuora is released under the MIT license:

http://www.opensource.org/licenses/MIT

## Support

Bug reports and feature requests can be filed as github issues here:

https://github.com/sportngin/active_zuora/issues
