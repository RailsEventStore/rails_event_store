# frozen_string_literal: true

RSpec.shared_examples 'scheduler' do |scheduler|
  specify "#call" do
    expect(scheduler).to respond_to(:call).with(2).arguments
  end

  specify "#verify" do
    expect(scheduler).to respond_to(:verify).with(1).argument
  end
end
