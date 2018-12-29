module RubyEventStore::ROM
  RSpec.shared_examples :rom_spec_helper do |_rom_spec_helper_class|
    let(:env) { rom_helper.env }
    let(:container) { env.container }
    let(:rom_db) { container.gateways[:default] }

    around(:each) do |example|
      rom_helper.run_lifecycle { example.run }
    end

    specify '#env gives access to ROM container' do
      expect(subject.env.container).to be_a(::ROM::Container)
    end
  end
end
