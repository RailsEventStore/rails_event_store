require 'spec_helper'
require 'action_controller/railtie'
require 'rails_event_store/railtie'

module RailsEventStore
  RSpec.describe Railtie::RailsConfig do
    specify 'no config, use defaults' do
      rails_config =
        Railtie::RailsConfig.new(::Rails::Application::Configuration.new)
      expect(rails_config.request_metadata.({
        'action_dispatch.request_id' => 'dummy_id',
        'action_dispatch.remote_ip'  => 'dummy_ip'
      })).to(eq({
        request_id: 'dummy_id',
        remote_ip:  'dummy_ip'
      }))
    end

    specify 'config present' do
      rails_config =
        Railtie::RailsConfig.new(::Rails::Application::Configuration.new
          .tap { |c| c.rails_event_store = { request_metadata: ->(env) { { kaka: 'dudu' } } } })
      expect(rails_config.request_metadata.({
        'action_dispatch.request_id' => 'dummy_id',
        'action_dispatch.remote_ip'  => 'dummy_ip'
      })).to(eq({
        kaka: 'dudu',
      }))
    end

    specify 'config present, no callable' do
      rails_config =
        Railtie::RailsConfig.new(::Rails::Application::Configuration.new
          .tap { |c| c.rails_event_store = {} })
      expect(rails_config.request_metadata.({
        'action_dispatch.request_id' => 'dummy_id',
        'action_dispatch.remote_ip'  => 'dummy_ip'
      })).to(eq({
        request_id: 'dummy_id',
        remote_ip:  'dummy_ip'
      }))
    end
  end
end
