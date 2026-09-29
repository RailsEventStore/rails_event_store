# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe RetryPolicy do
      let(:now) { Time.utc(2026, 9, 29, 12, 0, 0) }
      let(:no_jitter) { double(:random, rand: 0.0) }

      describe "#retry?" do
        specify "retries until attempts reach max_attempts" do
          policy = RetryPolicy.new(max_attempts: 3)

          expect(policy.retry?(RuntimeError.new, 1)).to eq(true)
          expect(policy.retry?(RuntimeError.new, 2)).to eq(true)
          expect(policy.retry?(RuntimeError.new, 3)).to eq(false)
        end

        specify "never retries an instance of a permanent error class, including its subclasses" do
          permanent = Class.new(StandardError)
          policy = RetryPolicy.new(permanent_errors: [permanent])

          expect(policy.retry?(permanent.new, 1)).to eq(false)
          expect(policy.retry?(Class.new(permanent).new, 1)).to eq(false)
          expect(policy.retry?(RuntimeError.new, 1)).to eq(true)
        end

        specify "defaults to 25 attempts and no permanent errors" do
          policy = RetryPolicy.new

          expect(policy.max_attempts).to eq(25)
          expect(policy.retry?(StandardError.new, 24)).to eq(true)
          expect(policy.retry?(StandardError.new, 25)).to eq(false)
        end
      end

      describe "#next_attempt_at" do
        specify "doubles the delay from base_delay with every attempt" do
          policy = RetryPolicy.new(base_delay: 2, max_delay: 1000, random: no_jitter)

          expect([1, 2, 3, 4].map { |attempts| policy.next_attempt_at(attempts, now) - now }).to eq([2, 4, 8, 16])
        end

        specify "caps the delay at max_delay" do
          policy = RetryPolicy.new(base_delay: 1, max_delay: 10, random: no_jitter)

          expect(policy.next_attempt_at(20, now)).to eq(now + 10)
        end

        specify "stretches the delay by up to jitter" do
          policy = RetryPolicy.new(base_delay: 10, max_delay: 1000, jitter: 0.5, random: double(:random, rand: 0.5))

          expect(policy.next_attempt_at(1, now)).to eq(now + 12.5)
        end

        specify "defaults to a 1 second base delay, a 1 hour cap and 20% jitter" do
          policy = RetryPolicy.new(random: double(:random, rand: 1.0))

          expect(policy.next_attempt_at(1, now)).to eq(now + 1.2)
          expect(policy.next_attempt_at(25, now)).to eq(now + 4320)
        end

        specify "spreads the default attempts over roughly 13 hours" do
          policy = RetryPolicy.new(random: no_jitter)

          total = (1...policy.max_attempts).sum { |attempts| policy.next_attempt_at(attempts, now) - now }

          expect(total / 3600.0).to be_within(0.5).of(13.1)
        end
      end

      specify "uses a real random generator by default, stretching the delay within the jitter" do
        policy = RetryPolicy.new

        expect(policy.instance_variable_get(:@random)).to be_an_instance_of(Random)
        expect(policy.next_attempt_at(1, now)).to be_between(now + 1, now + 1.2)
      end

      specify "accepts a single attempt, after which nothing is retried" do
        policy = RetryPolicy.new(max_attempts: 1)

        expect(policy.retry?(RuntimeError.new, 1)).to eq(false)
      end

      specify "rejects max_attempts below 1" do
        expect { RetryPolicy.new(max_attempts: 0) }.to raise_error(ArgumentError, "max_attempts must be at least 1")
      end
    end
  end
end
