require 'spec_helper.rb'

module RailsEventStore
  describe Client do
    it "is available in namespace" do
      RailsEventStore::Command.new
    end
  end
end
