require 'spec_helper'
require 'timeout'

module RubyEventStore
  RSpec.describe Debouncer do

    SAFETY_NET=5

    specify "waits 'delay' amount of time when fast jobs", mutant: false do
      a = []
      d = Debouncer.new(delay: delay = 0.020, timeout: 2) do
        a << Time.now
      end
      while a.size < 10
        rand(10).times{ d.call }
        Thread.pass
      end

      a.each_cons(2) do |earlier, later|
        expect(later.to_f - earlier.to_f).to be >= delay
        expect(later.to_f - earlier.to_f).to be <= delay*SAFETY_NET
      end
    end

    specify "waits 'delay+job' amount of time normally", mutant: false do
      a = []
      job = 0.010
      d = Debouncer.new(delay: delay = 0.020) do
        a << Time.now
        sleep(job)
      end
      while a.size < 10
        rand(10).times{ d.call }
        Thread.pass
      end
      a.each_cons(2) do |earlier, later|
        expect(later.to_f - earlier.to_f).to be >= delay+job
        expect(later.to_f - earlier.to_f).to be <= (delay+job)*SAFETY_NET
      end
    end

    specify "waits 'timeout' amount of time when job is lagging", mutant: false do
      a = []
      job = 0.500
      d = Debouncer.new(delay: 0.000, timeout: timeout = 0.020) do
        a << Time.now
        sleep(job)
      end
      while a.size < 10
        rand(10).times{ d.call }
        Thread.pass
      end
      a.each_cons(2) do |earlier, later|
        expect(later.to_f - earlier.to_f).to be >= timeout
        expect(later.to_f - earlier.to_f).to be <= timeout*SAFETY_NET
      end
    end

    specify "waits 'delay' amount of time when job is crashing", mutant: false do
      times = []
      threads = []
      d = Debouncer.new(delay: delay = 0.020, timeout: 2) do
        times << Time.now
        threads << Thread.current.object_id
        raise "x"
      end
      while times.size < 10
        rand(10).times{ d.call }
        Thread.pass
      end

      times.each_cons(2) do |earlier, later|
        expect(later.to_f - earlier.to_f).to be >= delay
        expect(later.to_f - earlier.to_f).to be <= delay*SAFETY_NET
      end

      expect(threads.uniq.size).to eq(1)
    end

    specify "creates new consumer if it crashes", mutant: false do
      threads = []
      supported = Thread.current.respond_to?(:report_on_exception=)
      d = Debouncer.new(delay: 0.020) do
        Thread.current.report_on_exception = false if supported
        threads << Thread.current.object_id
        raise Exception
      end
      while threads.size < 4
        rand(10).times{ d.call }
        Thread.pass
      end

      expect(threads.size).to be >= 4
      expect(threads.uniq.sort).to eq(threads.sort)
    end
  end
end