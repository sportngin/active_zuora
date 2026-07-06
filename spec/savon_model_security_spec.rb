require 'spec_helper'

describe Savon::Model do
  it 'treats SOAP action names as data when generating methods' do
    evidence = File.expand_path('../pwned_savon_model_spec', __dir__)
    File.delete(evidence) if File.exist?(evidence)

    action = "safe_action\nend\nFile.write(#{evidence.inspect}, 'exploited')\ndef unsafe_action"
    model = Class.new { extend Savon::Model }

    expect { model.actions(action) }.not_to change { File.exist?(evidence) }.from(false)
  ensure
    File.delete(evidence) if evidence && File.exist?(evidence)
  end
end
