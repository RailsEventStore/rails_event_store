# frozen_string_literal: true

module RubyEventStore
  module Flipper
    module Events
      class ToggleAdded < RubyEventStore::Event
      end

      class ToggleRemoved < RubyEventStore::Event
      end

      class ToggleGloballyEnabled < RubyEventStore::Event
      end

      class ToggleGloballyDisabled < RubyEventStore::Event
      end

      class ToggleEnabledForActor < RubyEventStore::Event
      end

      class ToggleDisabledForActor < RubyEventStore::Event
      end

      class ToggleEnabledForGroup < RubyEventStore::Event
      end

      class ToggleDisabledForGroup < RubyEventStore::Event
      end

      class ToggleEnabledForPercentageOfActors < RubyEventStore::Event
      end

      class ToggleDisabledForPercentageOfActors < RubyEventStore::Event
      end

      class ToggleEnabledForPercentageOfTime < RubyEventStore::Event
      end

      class ToggleDisabledForPercentageOfTime < RubyEventStore::Event
      end
    end
  end
end
