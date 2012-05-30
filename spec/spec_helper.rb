require 'rubygems'
require 'rspec'
require 'active_zuora'

ActiveZuora.configure(
  :log => ENV['DEBUG'],
  :username => ENV['ZUORA_USER'],
  :password => ENV['ZUORA_PASS']
)

module Z; end
ActiveZuora.generate_classes :module => Z
