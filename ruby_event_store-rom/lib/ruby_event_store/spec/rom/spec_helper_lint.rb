module RubyEventStore
  module ROM
  RSpec.shared_examples :rom_spec_helper do |_rom_spec_helper_class|
    let(:env) { rom_helper.env }
    let(:rom_container) { env.rom_container }
    let(:rom_db) { rom_container.gateways[:default] }

    around(:each) do |example|
      rom_helper.run_lifecycle { example.run }
    end

    specify '#env gives access to ROM container' do
      expect(subject.env.rom_container).to be_a(::ROM::Container)
    end
  end
  end
end
