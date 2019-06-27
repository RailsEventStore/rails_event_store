require 'spec_helper'

module RubyEventStore
  RSpec.describe Mappers do
    specify do
      expect { RubyEventStore::Mappers::MissingEncryptionKey }.to output(<<~MSG).to_stderr
        `RubyEventStore::Mappers::MissingEncryptionKey` has been deprecated. Use `RubyEventStore::Mappers::Transformation::Encryption::MissingEncryptionKey` instead.
      MSG
    end

    specify do
      silence_warnings { expect(Mappers::MissingEncryptionKey).to eq(Mappers::Transformation::Encryption::MissingEncryptionKey) }
    end

    specify do
      expect { Mappers::NoSuchConst }.to raise_error(NameError)
    end
  end
end
