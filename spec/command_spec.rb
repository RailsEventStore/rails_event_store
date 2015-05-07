require 'spec_helper.rb'

module Commands
  class CreateOrder < RailsEventStore::Command
    attr_accessor :order_id

    validates :order_id, presence: true
  end
end

module RailsEventStore
  describe Client do
    it "should have validations" do
      cmd = Commands::CreateOrder.new
      cmd.order_id = 5
      expect(cmd.valid?).to eq(true)
    end

    it "#validate! should validate command" do
      cmd = Commands::CreateOrder.new
      cmd.order_id = 5
      cmd.validate!
    end

    it "should raise error if order is not valid" do
      cmd = Commands::CreateOrder.new
      expect do
        cmd.validate!
      end.to raise_error(RailsEventStore::Command::ValidationError)
    end
  end
end
