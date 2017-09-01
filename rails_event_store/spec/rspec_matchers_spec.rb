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

      specify do
        expect(CouponRedeemed.new(data: { code: '123' }))
          .to(matcher(CouponRedeemed).with_data(code: '123'))
      end

      specify do
        expect(CouponRedeemed.new(data: { code: '123' }))
          .to_not(matcher(CouponRedeemed).with_data(code: '456'))
      end

      specify 'partial data match' do
        expect(CouponRedeemed.new(data: { code: '123', foo: 1 }))
          .to(matcher(CouponRedeemed).with_data(code: '123'))
      end

      specify do
        expect(CouponRedeemed.new(data: { code: '123' }))
          .to_not(matcher(CouponRedeemed).with_data(code: '123', bar: 2))
      end

      specify do
        expect(CouponRedeemed.new(metadata: { request_id: 'abc' }))
          .to(matcher(CouponRedeemed).with_metadata(request_id: 'abc'))
      end

      specify do
        expect(CouponRedeemed.new(metadata: { request_id: 'abc' }))
          .to_not(matcher(CouponRedeemed).with_metadata(request_id: 'def'))
      end

      specify 'partial metadata match' do
        expect(CouponRedeemed.new(metadata: { request_id: 'abc', remote_ip: '1.2.3.4' }))
          .to(matcher(CouponRedeemed).with_metadata(request_id: 'abc'))
      end

      specify do
        expect(CouponRedeemed.new(metadata: { request_id: 'abc' }))
          .to_not(matcher(CouponRedeemed).with_metadata(request_id: 'abc', remote_ip: '1.2.3.4'))
      end

      specify do
        expect(CouponRedeemed.new(data: { code: '123' }, metadata: { request_id: '456' }))
          .to(matcher(CouponRedeemed).with_data(code: '123').and_metadata(request_id: '456'))
      end

      specify do
        expect(CouponRedeemed.new(data: { code: '123' }, metadata: { request_id: '456' }))
          .to(matcher(CouponRedeemed).with_metadata(request_id: '456').and_data(code: '123'))
      end
    end
  end
end
