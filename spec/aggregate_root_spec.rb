require 'spec_helper.rb'

class Order
  include RailsEventStore::AggregateRoot

  def initialize(id = generate_uuid)
    @id = id
  end

  attr_accessor :id
end

module RailsEventStore
  describe Client do
    it "should be able to generate UUID if user won't provide it's own" do
      order1 = Order.new
      order2 = Order.new
      expect(order1.id).to_not eq(order2.id)
      expect(order1.id).to be_a(String)
    end
  end
end
