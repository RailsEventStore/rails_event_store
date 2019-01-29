require "spec_helper"

module RailsEventStore
  module RSpec
    ::RSpec.describe SuperDiffStructuralDiffer do
      let(:color_blind_differ)     { SuperDiffStructuralDiffer.new(color: false) }
      let(:colored_differ)         { SuperDiffStructuralDiffer.new(color: true) }
      let(:colored_differ)         { SuperDiffStructuralDiffer.new(color: true) }
      let(:colored_differ_default) { SuperDiffStructuralDiffer.new }

      OUTPUT_WITHOUT_COLORS = <<~EOS
          Differing hashes.
          
          Expected: { key: "value" }
            Actual: {  }
         
          Diff:
          
            {
          -   key: "value"
            }
      EOS

      COLORED_OUTPUT = <<~EOS
          Differing hashes.
          
          \e[31mExpected: { key: "value" }\e[0m
          \e[32m  Actual: {  }\e[0m
         
          Diff:
          
            {
          \e[31m-   key: "value"\e[0m
            }
      EOS

      specify do
        expect(color_blind_differ.diff({}, {})).to eq ''
      end

      specify do
        expect(colored_differ.diff({}, {})).to eq ''
      end

      specify do
        expect(color_blind_differ.diff({key: 'value'}, {})).to eq(OUTPUT_WITHOUT_COLORS)
      end

      specify do
        expect(colored_differ.diff({key: 'value'}, {})).to eq(COLORED_OUTPUT)
      end

      specify do
        expect(colored_differ_default.diff({key: 'value'}, {})).to eq(COLORED_OUTPUT)
      end
    end
  end
end

