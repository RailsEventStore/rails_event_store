require 'spec_helper'

module RubyEventStore::ROM
  RSpec.describe Env do
    let(:container) { ::ROM.container }
    let(:instance) { Env.new(container) }

    specify '#container gives access to ROM container' do
      expect(instance.container).to be_a(::ROM::Container)
    end

    specify '#logger gives access to Logger' do
      expect(instance.logger).to be_a(Logger)
    end
  end
end
