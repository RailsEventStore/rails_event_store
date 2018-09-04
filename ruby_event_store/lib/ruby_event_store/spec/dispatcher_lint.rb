RSpec.shared_examples :dispatcher do |dispatcher|
  specify "#call" do
    expect(dispatcher).to respond_to(:call).with(3).arguments
  end

  specify "#verify" do
    expect(dispatcher).to respond_to(:verify).with(1).argument
  end
end
