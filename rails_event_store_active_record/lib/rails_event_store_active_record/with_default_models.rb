# frozen_string_literal: true

module RailsEventStoreActiveRecord
  class WithDefaultModels
    def call
      [Event, EventInStream]
    end
  end
end
