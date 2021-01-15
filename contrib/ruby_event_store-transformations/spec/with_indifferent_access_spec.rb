# frozen_string_literal: true

require 'spec_helper'

module RubyEventStore
  module Transformations
    RSpec.describe WithIndifferentAccess do
      def record(hash, time)
        RubyEventStore::Record.new(
          event_id:   'not-important',
          data:       hash,
          metadata:   hash,
          event_type: 'does-not-matter',
          timestamp:  time,
          valid_at:   time,
        )
     end

      specify "#load" do
        time = Time.now
        hash =
          {
            simple: 'data',
            array: [
              1,2,3, {some: 'hash'}
            ],
            hash: {
              nested: {
                any: 'value'
              },
              meh: 3
            }
          }
        result = WithIndifferentAccess.new.load(record(hash, time))

        expect(result.data).to                 be_kind_of(ActiveSupport::HashWithIndifferentAccess)
        expect(result.metadata).to             be_kind_of(ActiveSupport::HashWithIndifferentAccess)
        expect(result.data[:array].last).to    be_kind_of(ActiveSupport::HashWithIndifferentAccess)
        expect(result.data[:hash]).to          be_kind_of(ActiveSupport::HashWithIndifferentAccess)
        expect(result.data[:hash][:nested]).to be_kind_of(ActiveSupport::HashWithIndifferentAccess)

        expect(result.data[:simple]).to              eq('data')
        expect(result.data[:array].first).to         eq(1)
        expect(result.data[:array].last[:some]).to   eq('hash')
        expect(result.data[:hash][:meh]).to          eq(3)
        expect(result.data[:hash][:nested][:any]).to eq('value')

        expect(result.data['simple']).to                eq('data')
        expect(result.data['array'].first).to           eq(1)
        expect(result.data['array'].last['some']).to    eq('hash')
        expect(result.data['hash']['meh']).to           eq(3)
        expect(result.data['hash']['nested']['any']).to eq('value')

        expect(result.timestamp).to eq(time)
        expect(result.valid_at).to  eq(time)
      end

      specify "#dump" do
        time = Time.now
        hash =
          ActiveSupport::HashWithIndifferentAccess.new({
            simple: 'data',
            array: [
              1,2,3, ActiveSupport::HashWithIndifferentAccess.new({some: 'hash'})
            ],
            hash: ActiveSupport::HashWithIndifferentAccess.new({
              nested: ActiveSupport::HashWithIndifferentAccess.new({
                any: 'value'
              }),
              meh: 3
            })
          })
        result = WithIndifferentAccess.new.dump(record(hash, time))

        expect(result.data).to                 be_kind_of(Hash)
        expect(result.metadata).to             be_kind_of(Hash)
        expect(result.data[:array].last).to    be_kind_of(Hash)
        expect(result.data[:hash]).to          be_kind_of(Hash)
        expect(result.data[:hash][:nested]).to be_kind_of(Hash)

        expect(result.data[:simple]).to              eq('data')
        expect(result.data[:array].first).to         eq(1)
        expect(result.data[:array].last[:some]).to   eq('hash')
        expect(result.data[:hash][:meh]).to          eq(3)
        expect(result.data[:hash][:nested][:any]).to eq('value')

        expect(result.timestamp).to eq(time)
        expect(result.valid_at).to  eq(time)
      end
    end
  end
end
