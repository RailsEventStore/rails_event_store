# frozen_string_literal: true

module RailsEventStore
  module Inspector
    ::RSpec.describe Configuration do
      specify "refuses when Rails is not around at all" do
        expect(Configuration.new.enabled.call({})).to be_falsey
      end

      specify "allows development" do
        stub_const("Rails", double(env: double(development?: true)))

        expect(Configuration.new.enabled.call({})).to be(true)
      end

      specify "refuses every other environment" do
        stub_const("Rails", double(env: double(development?: false)))

        expect(Configuration.new.enabled.call({})).to be(false)
      end

      specify "the predicate sees the request, so it can decide per visitor" do
        config = Configuration.new
        config.enabled = ->(env) { env["staff"] == true }

        expect(config.enabled.call("staff" => true)).to be(true)
        expect(config.enabled.call("staff" => false)).to be(false)
      end
    end

    ::RSpec.describe "Inspector.configure" do
      specify "yields the memoized configuration" do
        Inspector.configure { |config| config.enabled = ->(_) { :marker } }

        expect(Inspector.configuration.enabled.call({})).to eq(:marker)
      end
    end
  end
end
