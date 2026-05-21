# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyEventStore::Deprecations do

  it "emits registered warning to stderr" do
    described_class.register(:foo, "foo is deprecated")
    expect { described_class.warn(:foo) }.to output(/foo is deprecated/).to_stderr
  end

  it "suppresses warning when told to" do
    described_class.register(:foo, "foo is deprecated")
    described_class.suppress(:foo)
    expect { described_class.warn(:foo) }.not_to output.to_stderr
  end

  it "emits warning only once even if called multiple times" do
    described_class.register(:foo, "foo is deprecated")
    expect { 3.times { described_class.warn(:foo) } }
      .to output("[DEPRECATION] foo is deprecated\n").to_stderr
  end

  it "emits message keyword argument instead of registered message" do
    described_class.register(:foo, "foo registered message")
    expect { described_class.warn(:foo, message: "custom override message") }
      .to output(/custom override message/).to_stderr
  end

  it "reset! clears suppressions so previously suppressed warning can fire again" do
    described_class.register(:foo, "foo is deprecated")
    described_class.suppress(:foo)
    described_class.reset!
    expect { described_class.warn(:foo) }.to output(/foo is deprecated/).to_stderr
  end

  describe ".deprecate" do
    it "fires deprecation on instance method call" do
      klass = Class.new { def greet; "hello"; end }
      described_class.register(:greet, "greet is deprecated")
      described_class.deprecate(klass, :greet, key: :greet)
      expect { klass.new.greet }.to output(/greet is deprecated/).to_stderr
    end

    it "preserves return value" do
      klass = Class.new { def greet; "hello"; end }
      described_class.register(:greet, "greet is deprecated")
      described_class.deprecate(klass, :greet, key: :greet)
      expect(klass.new.greet).to eq("hello")
    end

    it "forwards positional arguments" do
      klass = Class.new { def greet(name); "hello #{name}"; end }
      described_class.register(:greet, "greet is deprecated")
      described_class.deprecate(klass, :greet, key: :greet)
      expect(klass.new.greet("world")).to eq("hello world")
    end

    it "forwards keyword arguments" do
      klass = Class.new { def greet(name:); "hello #{name}"; end }
      described_class.register(:greet, "greet is deprecated")
      described_class.deprecate(klass, :greet, key: :greet)
      expect(klass.new.greet(name: "world")).to eq("hello world")
    end

    it "forwards blocks" do
      klass = Class.new { def greet(&blk); blk.call; end }
      described_class.register(:greet, "greet is deprecated")
      described_class.deprecate(klass, :greet, key: :greet)
      expect(klass.new.greet { "hi" }).to eq("hi")
    end

    it "preserves private visibility" do
      klass = Class.new { private; def secret; "shh"; end }
      described_class.register(:secret, "secret is deprecated")
      described_class.deprecate(klass, :secret, key: :secret)
      expect { klass.new.secret }.to raise_error(NoMethodError, /private/)
    end
  end

  describe ".deprecate_class_method" do
    it "fires deprecation on class method call" do
      klass = Class.new { def self.build; "built"; end }
      described_class.register(:build, "build is deprecated")
      described_class.deprecate_class_method(klass, :build, key: :build)
      expect { klass.build }.to output(/build is deprecated/).to_stderr
    end

    it "preserves return value" do
      klass = Class.new { def self.build; "built"; end }
      described_class.register(:build, "build is deprecated")
      described_class.deprecate_class_method(klass, :build, key: :build)
      expect(klass.build).to eq("built")
    end

    it "forwards positional arguments" do
      klass = Class.new { def self.build(from); "built #{from}"; end }
      described_class.register(:build, "build is deprecated")
      described_class.deprecate_class_method(klass, :build, key: :build)
      expect(klass.build("scratch")).to eq("built scratch")
    end

    it "forwards keyword arguments" do
      klass = Class.new { def self.build(from:); "built #{from}"; end }
      described_class.register(:build, "build is deprecated")
      described_class.deprecate_class_method(klass, :build, key: :build)
      expect(klass.build(from: "scratch")).to eq("built scratch")
    end

    it "forwards blocks" do
      klass = Class.new { def self.build(&blk); blk.call; end }
      described_class.register(:build, "build is deprecated")
      described_class.deprecate_class_method(klass, :build, key: :build)
      expect(klass.build { "hi" }).to eq("hi")
    end
  end
end
