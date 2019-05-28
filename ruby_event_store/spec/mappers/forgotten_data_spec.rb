require 'spec_helper'

module RubyEventStore
  module Mappers
    RSpec.describe ForgottenData do
      specify 'compares with string' do
        expect(ForgottenData.new).to                eq(ForgottenData::FORGOTTEN_DATA)
        expect(ForgottenData.new('bazinga')).to     eq('bazinga')
        expect(ForgottenData.new('bazinga')).not_to eq(ForgottenData::FORGOTTEN_DATA)
      end

      specify "prints as string" do
        expect{ print(ForgottenData.new) }.to            output(ForgottenData::FORGOTTEN_DATA).to_stdout
        expect{ print(ForgottenData.new('bazinga')) }.to output('bazinga').to_stdout
      end

      specify 'behaves like null object' do
        data = ForgottenData.new
        expect(data.foo.bar[:baz]).to eq(data)
      end
    end
  end
end
