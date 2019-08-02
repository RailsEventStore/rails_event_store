require 'spec_helper'

module Transformations
  RSpec.describe WithIndifferentAccess do
    let(:item) {
      RubyEventStore::Mappers::Transformation::Item.new(
        event_id: 'not-important',
        data: hash,
        metadata: hash,
        event_type: 'does-not-matter',
      )
    }

    context "#load" do
      let(:hash) {
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
      }

      it do
        result = WithIndifferentAccess.new.load(item)
        expect(result.data.class).to eq(ActiveSupport::HashWithIndifferentAccess)
        expect(result.data[:array].last.class).to eq(ActiveSupport::HashWithIndifferentAccess)
        expect(result.data[:hash].class).to eq(ActiveSupport::HashWithIndifferentAccess)
        expect(result.data[:hash][:nested].class).to eq(ActiveSupport::HashWithIndifferentAccess)

        expect(result.data[:simple]).to eq('data')
        expect(result.data[:array].first).to eq(1)
        expect(result.data[:array].last[:some]).to eq('hash')
        expect(result.data[:hash][:meh]).to eq(3)
        expect(result.data[:hash][:nested][:any]).to eq('value')

        expect(result.data['simple']).to eq('data')
        expect(result.data['array'].first).to eq(1)
        expect(result.data['array'].last['some']).to eq('hash')
        expect(result.data['hash']['meh']).to eq(3)
        expect(result.data['hash']['nested']['any']).to eq('value')
      end
    end

    context "#dump" do
      let(:hash) {
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
      }

      it do
        result = WithIndifferentAccess.new.dump(item)
        expect(result.data.class).to eq(Hash)
        expect(result.data[:array].last.class).to eq(Hash)
        expect(result.data[:hash].class).to eq(Hash)
        expect(result.data[:hash][:nested].class).to eq(Hash)

        expect(result.data[:simple]).to eq('data')
        expect(result.data[:array].first).to eq(1)
        expect(result.data[:array].last[:some]).to eq('hash')
        expect(result.data[:hash][:meh]).to eq(3)
        expect(result.data[:hash][:nested][:any]).to eq('value')
      end
    end
  end
end
