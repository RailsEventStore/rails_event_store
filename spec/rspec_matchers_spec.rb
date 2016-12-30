require 'spec_helper'
require 'rails_event_store/rspec'

CouponActivated = Class.new(RailsEventStore::Event)
CouponRedeemed  = Class.new(RailsEventStore::Event)

module RailsEventStore
  module RSpecMatchers
    RSpec.describe 'matcher aliases' do
      include ::RailsEventStore::RSpecMatchers

      specify { expect(be_event(CouponRedeemed)).to be_kind_of(BeEvent) }
      specify { expect(an_event(CouponRedeemed)).to be_kind_of(BeEvent) }
    end

    RSpec.describe BeEvent do
      def matcher(expected)
        BeEvent.new(expected)
      end

      specify do
        expect(CouponRedeemed.new).to matcher(CouponRedeemed)
      end

      specify do
        expect(CouponRedeemed.new).to_not matcher(CouponActivated)
      end

      specify do
        _matcher = matcher(CouponActivated)
        _matcher.matches?(CouponRedeemed.new)

        expect(_matcher.description).to eq("be an event of kind CouponActivated")
      end

      specify do
        _matcher = matcher(CouponActivated)
        _matcher.matches?(CouponRedeemed.new)

        expect(_matcher.failure_message).to eq(%q{
expected: CouponActivated
     got: CouponRedeemed
        })
      end

      specify do
        _matcher = matcher(CouponRedeemed)
        _matcher.matches?(CouponRedeemed.new)

        expect(_matcher.failure_message_when_negated).to eq(%q{
expected: not kind of CouponRedeemed
     got: CouponRedeemed
        })
      end
    end
  end
end
