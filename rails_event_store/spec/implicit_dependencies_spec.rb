# frozen_string_literal: true

require "spec_helper"

module RailsEventStore
  ::RSpec.describe ImplicitDependencies do
    specify "warns when command bus is used but not declared in the Gemfile" do
      stub_const("Arkency::CommandBus", Class.new)
      hide_const("AggregateRoot")

      expect { ImplicitDependencies.check(%w[rails_event_store]) }.to output(<<~EOS).to_stderr
        [DEPRECATION] rails_event_store 4.0 will no longer depend on arkency-command_bus.

        Your application uses Arkency::CommandBus without declaring arkency-command_bus in its Gemfile.
        Add it there to keep it after the upgrade:

          gem "arkency-command_bus"
      EOS
    end

    specify "warns when aggregate root is used but not declared in the Gemfile" do
      stub_const("AggregateRoot", Module.new)
      hide_const("Arkency::CommandBus")

      expect { ImplicitDependencies.check(%w[rails_event_store]) }.to output(<<~EOS).to_stderr
        [DEPRECATION] rails_event_store 4.0 will no longer depend on aggregate_root.

        Your application uses AggregateRoot without declaring aggregate_root in its Gemfile.
        Add it there to keep it after the upgrade:

          gem "aggregate_root"
      EOS
    end

    specify "stays silent when used gems are declared in the Gemfile" do
      stub_const("Arkency::CommandBus", Class.new)
      stub_const("AggregateRoot", Module.new)

      expect {
        ImplicitDependencies.check(%w[rails_event_store aggregate_root arkency-command_bus])
      }.not_to output.to_stderr
    end

    specify "declaring one gem does not silence the other" do
      stub_const("Arkency::CommandBus", Class.new)
      stub_const("AggregateRoot", Module.new)

      expect { ImplicitDependencies.check(%w[rails_event_store aggregate_root]) }.to output(
        /will no longer depend on arkency-command_bus/,
      ).to_stderr
    end

    specify "stays silent when undeclared gems are not used" do
      hide_const("Arkency::CommandBus")
      hide_const("AggregateRoot")

      expect { ImplicitDependencies.check(%w[rails_event_store]) }.not_to output.to_stderr
    end

    around do |example|
      RubyEventStore::Deprecations.reset!
      example.run
      RubyEventStore::Deprecations.reset!
    end
  end
end
