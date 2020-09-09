require 'spec_helper'
require 'ruby_event_store/rom/memory'
require 'ruby_event_store/spec/rom/spec_helper_lint'

module RubyEventStore
  module ROM
  module Memory
  RSpec.describe SpecHelper do
    let(:rom_helper) { SpecHelper.new }

    it_behaves_like :rom_spec_helper, SpecHelper
  end
  end
  end
end
