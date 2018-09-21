require 'spec_helper'

RSpec.describe 'ruby_26_google_protobuf_support' do
  specify do
    skip unless RUBY_VERSION.start_with? '2.6'

    expect do
      require 'google-protobuf'
    end.to raise_error(LoadError)
  end
end