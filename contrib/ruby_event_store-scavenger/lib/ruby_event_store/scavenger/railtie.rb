# frozen_string_literal: true

module RubyEventStore
  module Scavenger
    class Railtie < ::Rails::Railtie
      rake_tasks { load File.expand_path("tasks/scavenge.rake", __dir__) }
    end
  end
end
