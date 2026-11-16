# frozen_string_literal: true

module RailsEventStore
  class ImplicitDependencies
    GEMS = { "aggregate_root" => "AggregateRoot", "arkency-command_bus" => "Arkency::CommandBus" }.freeze

    GEMS.each do |gem_name, constant|
      RubyEventStore::Deprecations.register(:"rails_event_store_implicit_#{gem_name}", <<~EOW)
        rails_event_store 4.0 will no longer depend on #{gem_name}.

        Your application uses #{constant} without declaring #{gem_name} in its Gemfile.
        Add it there to keep it after the upgrade:

          gem "#{gem_name}"
      EOW
    end

    def self.check(declared_gems)
      GEMS.each do |gem_name, constant|
        next if declared_gems.include?(gem_name)
        next unless const_defined?(constant)
        RubyEventStore::Deprecations.warn(:"rails_event_store_implicit_#{gem_name}")
      end
    end
  end
end
