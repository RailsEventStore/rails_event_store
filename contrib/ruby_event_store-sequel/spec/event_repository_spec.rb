require "spec_helper"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  module Sequel
    ::RSpec.describe EventRepository do
      helper = SpecHelper.new
      mk_repository = -> do
        serializer =
          case ENV["DATA_TYPE"]
          when /json/
            JSON
          else
            RubyEventStore::Serializers::YAML
          end
        EventRepository.new(sequel: helper.sequel, serializer: serializer)
      end

      it_behaves_like :event_repository, mk_repository, helper

      around(:each) { |example| helper.run_lifecycle { example.run } }
    end
  end
end
