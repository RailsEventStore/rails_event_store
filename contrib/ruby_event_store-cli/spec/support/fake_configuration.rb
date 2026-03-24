# frozen_string_literal: true

class FakeConfiguration
  def initialize
    @options = {}
  end

  def respond_to_missing?(name, include_private = false)
    @options.key?(name) || super
  end

  private

  def method_missing(name, *args, &blk)
    if name.to_s.end_with?("=")
      @options[name.to_s.chomp("=").to_sym] = args.first
    elsif @options.key?(name)
      @options[name]
    else
      super
    end
  end
end
