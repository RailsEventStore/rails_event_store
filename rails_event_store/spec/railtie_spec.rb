require 'spec_helper'
require 'action_controller/railtie'
require 'rails_event_store/railtie'

module RailsEventStore
  RSpec.describe Railtie::RailsConfig do
    specify 'no config, use defaults' do
      rails_config = Railtie::RailsConfig.new(app_configuration)

      expect(rails_config.request_metadata.(dummy_env))
        .to(eq({
          request_id: 'dummy_id',
          remote_ip:  'dummy_ip'
        }))
    end

    specify 'config present' do
      app_configuration.rails_event_store = { request_metadata: kaka_dudu }
      rails_config = Railtie::RailsConfig.new(app_configuration)

      expect(rails_config.request_metadata.(dummy_env)).to eq({ kaka: 'dudu' })
    end

    specify 'config present, no callable' do
      app_configuration.rails_event_store = {}
      rails_config = Railtie::RailsConfig.new(app_configuration)

      expect(rails_config.request_metadata.(dummy_env))
        .to(eq({
          request_id: 'dummy_id',
          remote_ip:  'dummy_ip'
        }))
    end

    def app_configuration
      @app_configuration ||= FakeConfiguration.new
    end

    def kaka_dudu
      ->(env) { { kaka: 'dudu' } }
    end

    def dummy_env
      {
        'action_dispatch.request_id' => 'dummy_id',
        'action_dispatch.remote_ip'  => 'dummy_ip'
      }
    end
  end

  class FakeConfiguration
    def initialize
      @options = {}
    end

    private

    def method_missing(name, *args, &blk)
      if name.to_s =~ /=$/
        @options[$`.to_sym] = args.first
      elsif @options.key?(name)
        @options[name]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      @options.key?(name) || super
    end
  end
end
