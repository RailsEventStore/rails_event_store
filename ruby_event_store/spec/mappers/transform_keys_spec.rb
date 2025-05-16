# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe TransformKeys do
    let(:hash_with_symbols) do
      {
        one: 1,
        two: 2.0,
        three: true,
        four: Date.new(2018, 4, 17),
        five: "five",
        six: Time.utc(2018, 12, 13, 11),
        seven: true,
        eight: false,
        nein: nil,
        ten: {
          some: "hash",
          with: {
            nested: "values",
          },
        },
        eleven: [1, { another: "hash", here: 2 }, 3],
        array: [
          123,
          { twelve: { meh: "doh" } },
          [456, { thirteen: { another_array: [789, { fourteen: { just: "one more" } }, "enough"] } }],
        ],
      }
    end
    let(:hash_with_strings) do
      {
        "one" => 1,
        "two" => 2.0,
        "three" => true,
        "four" => Date.new(2018, 4, 17),
        "five" => "five",
        "six" => Time.utc(2018, 12, 13, 11),
        "seven" => true,
        "eight" => false,
        "nein" => nil,
        "ten" => {
          "some" => "hash",
          "with" => {
            "nested" => "values",
          },
        },
        "eleven" => [1, { "another" => "hash", "here" => 2 }, 3],
        "array" => [
          123,
          { "twelve" => { "meh" => "doh" } },
          [456, { "thirteen" => { "another_array" => [789, { "fourteen" => { "just" => "one more" } }, "enough"] } }],
        ],
      }
    end

    it { expect(TransformKeys.stringify(hash_with_symbols)).to eq(hash_with_strings) }
    it { expect(TransformKeys.stringify(hash_with_strings)).to eq(hash_with_strings) }

    it { expect(TransformKeys.symbolize(hash_with_strings)).to eq(hash_with_symbols) }
    it { expect(TransformKeys.symbolize(hash_with_symbols)).to eq(hash_with_symbols) }
  end
end
