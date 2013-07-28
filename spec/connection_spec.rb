require 'spec_helper'

describe ActiveZuora::Connection do
  it { should respond_to(:session_id) }
  it { should respond_to(:soap_client) }
end
