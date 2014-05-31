require 'rubygems'
require 'rspec'
require 'active_zuora'

ActiveZuora.configure(
  :log => ENV['DEBUG'],
  :username => ENV['ZUORA_USER'],
  :password => ENV['ZUORA_PASS']
)

module Z; end
ActiveZuora.generate_classes :inside => Z

def integration_test
  # Block helper.  Integration tests should be wrapped in this block.
  if ENV['ZUORA_USER'] && ENV['ZUORA_PASS']
    yield
  else
    $stderr.puts "Integration tests skipped because ZUORA_USER or ZUORA_PASS are not set."
  end
end

module Tenant
  def self.currency
    ENV['ZUORA_CURRENCY'] || 'USD'
  end
end