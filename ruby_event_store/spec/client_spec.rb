require 'spec_helper'
require 'time'
require_relative 'client_examples'
require_relative 'mappers/events_pb.rb'

module RubyEventStore
  RSpec.describe Client do
    it_behaves_like :client, Client
  end
end
