module RubyEventStore
  module ROM
  RSpec.shared_examples :unit_of_work do |unit_of_work_class|
    subject(:unit_of_work) { unit_of_work_class.new(rom: env) }

    let(:env) { rom_helper.env }
    let(:v) { env.rom_container }
    let(:rom_db) { rom_container.gateways[:default] }

    around(:each) do |example|
      rom_helper.run_lifecycle { example.run }
    end

    specify '#env gives access to ROM container' do
      expect(subject.env.rom_container).to be_a(::ROM::Container)
    end

    specify '#call to throw an exeption' do
      expect { subject.call(gateway: nil) {} }.to raise_error(KeyError)
    end

    specify '#env is the instance we specified' do
      expect(subject.env).to eq(env)
    end

    specify '#env is the global instance' do
      RubyEventStore::ROM.env = rom_helper.class.new.env

      subject2 = unit_of_work_class.new

      expect(subject2.env).to eq(RubyEventStore::ROM.env)
      expect(subject2.env).not_to eq(subject.env)
      expect(subject.env).not_to eq(RubyEventStore::ROM.env)

      RubyEventStore::ROM.env = nil
    end
  end
  end
end
