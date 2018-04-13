require 'singleton'
require 'active_support/core_ext/module'
require 'json'
require 'snappy'

module RailsEventStoreActiveRecord
  class UuidSerializer
    include Singleton

    class << self
      delegate :dump, :load, to: :instance
    end

    def dump(uuid)
      return nil unless uuid
      return uuid unless uuid.is_a?(String) && uuid.size == 36
      @hyphen_remover ||= /-/
      hexadecimal = uuid.gsub(@hyphen_remover, '')
      [hexadecimal].pack('H*')
    end

    def load(binary)
      return nil unless binary
      return binary unless binary.is_a?(String) && binary.size == 16
      hexadecimal = binary.unpack('H*').first
      @hyphen_restorer ||= begin
        uuid_chunk_list = [8, 4, 4, 4, 12]
        chunks_pattern = uuid_chunk_list.
          map do |chunk_size|
          "([0-9a-f]{#{chunk_size}})"
        end.
          join
        Regexp.new(
          "\\A#{chunks_pattern}\\z",
          Regexp::IGNORECASE,
        )
      end
      hexadecimal.sub(@hyphen_restorer, '\1-\2-\3-\4-\5')
    end
  end

  class CompressionSerializer
    include Singleton

    class << self
      delegate :dump, :load, to: :instance
    end

    def dump(hash_object)
      return nil unless hash_object
      Snappy.dump(JSON.dump(hash_object))
    end

    def load(compressed_binary)
      return nil unless compressed_binary
      JSON.load(Snappy.load(compressed_binary))
    end
  end
end
