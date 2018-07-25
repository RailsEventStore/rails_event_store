require 'spec_helper'
require 'timeout'

module RubyEventStore
  RSpec.describe Debouncer do

    specify "waits 'delay' amount of time when fast jobs" do
      a = []
      d = Debouncer.new(delay: 0.020) do
        a << nil
      end
      expect do
        Timeout.timeout(0.3) do
          loop{ rand(10).times{ d.call }; Thread.pass }
        end
      end.to raise_error(Timeout::Error)
      expect(a.size).to be_between(13, 16)
    end

    specify "waits 'delay+job' amount of time normally" do
      a = []
      d = Debouncer.new(delay: 0.020) do
        a << nil
        sleep(0.010)
      end
      expect do
        Timeout.timeout(0.3) do
          loop{ rand(10).times{ d.call }; Thread.pass }
        end
      end.to raise_error(Timeout::Error)
      expect(a.size).to be_between(8, 11)
    end

    specify "waits 'timeout' amount of time when job is lagging" do
      a = []
      d = Debouncer.new(delay: 0.010, timeout: 0.020) do
        a << nil
        sleep(0.100)
      end
      expect do
        Timeout.timeout(0.3) do
          loop{ rand(10).times{ d.call }; Thread.pass }
        end
      end.to raise_error(Timeout::Error)
      expect(a.size).to be_between(13, 16)
    end

    specify "creates new consumer if it crashes" do
      a = []
      d = Debouncer.new(delay: 0.020) do
        a << nil
        raise "x"
      end
      expect do
        Timeout.timeout(0.3) do
          loop{ rand(10).times{ d.call }; Thread.pass }
        end
      end.to raise_error(Timeout::Error)
      expect(a.size).to be_between(13, 16)
    end
  end
end