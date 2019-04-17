module RubyEventStore
  module Mappers
    class ForgottenData
      FORGOTTEN_DATA = 'FORGOTTEN_DATA'.freeze

      def initialize(string = FORGOTTEN_DATA)
        @string = string
      end

      def to_s
        @string
      end

      def ==(other)
        @string == other
      end

      def method_missing(*)
        self
      end

      def respond_to_missing?(*)
        true
      end
    end

    class InMemoryEncryptionKeyRepository
      DEFAULT_CIPHER = 'aes-256-gcm'.freeze

      def initialize
        @keys = {}
      end

      def key_of(identifier, cipher: DEFAULT_CIPHER)
        @keys[[identifier, cipher]]
      end

      def create(identifier, cipher: DEFAULT_CIPHER)
        crypto = prepare_encrypt(cipher)
        @keys[[identifier, cipher]] = EncryptionKey.new(cipher: cipher, key: crypto.random_key)
      end

      def forget(identifier)
        @keys = @keys.reject { |(id, _)| id.eql?(identifier) }
      end

      private

      def prepare_encrypt(cipher)
        crypto = OpenSSL::Cipher.new(cipher)
        crypto.encrypt
        crypto
      end
    end

    class EncryptionKey
      def initialize(cipher:, key:)
        @cipher = cipher
        @key    = key
      end

      def encrypt(message, iv)
        crypto     = prepare_encrypt(cipher)
        crypto.iv  = iv
        crypto.key = key

        if crypto.authenticated?
          encrypt_authenticated(crypto, message)
        else
          crypto.update(message) + crypto.final
        end
      end

      def decrypt(message, iv)
        crypto     = prepare_decrypt(cipher)
        crypto.iv  = iv
        crypto.key = key
        ciphertext =
          if crypto.authenticated?
            ciphertext_from_authenticated(crypto, message)
          else
            message
          end
        (crypto.update(ciphertext) + crypto.final).force_encoding("UTF-8")
      end

      def random_iv
        crypto = prepare_encrypt(cipher)
        crypto.random_iv
      end

      attr_reader :cipher, :key

      private

      def ciphertext_from_authenticated(crypto, message)
        prepare_auth_data(crypto)
        crypto.auth_tag = message[-16...message.length]
        message[0...-16]
      end

      def encrypt_authenticated(crypto, message)
        prepare_auth_data(crypto)
        crypto.update(message) + crypto.final + crypto.auth_tag
      end

      def prepare_auth_data(crypto)
        crypto.auth_data = ""
        crypto
      end

      def prepare_encrypt(cipher)
        crypto = OpenSSL::Cipher.new(cipher)
        crypto.encrypt
        crypto
      end

      def prepare_decrypt(cipher)
        crypto = OpenSSL::Cipher.new(cipher)
        crypto.decrypt
        crypto
      end
    end

    class MissingEncryptionKey < StandardError
      def initialize(key_identifier)
        super %Q|Could not find encryption key for '#{key_identifier}'|
      end
    end

    class EncryptionMapper
      class Leaf
        def self.===(hash)
          hash.keys.sort.eql? %i(cipher identifier iv)
        end
      end
      private_constant :Leaf

      def initialize(key_repository, serializer: YAML, forgotten_data: ForgottenData.new)
        @key_repository = key_repository
        @serializer     = serializer
        @forgotten_data = forgotten_data
      end

      def event_to_serialized_record(domain_event)
        metadata              = domain_event.metadata.to_h
        crypto_description    = encryption_metadata(domain_event.data, encryption_schema(domain_event))
        metadata[:encryption] = crypto_description unless crypto_description.empty?

        SerializedRecord.new(
          event_id: domain_event.event_id,
          metadata: serializer.dump(metadata),
          data: serializer.dump(encrypt_data(deep_dup(domain_event.data), crypto_description)),
          event_type: domain_event.class.to_s
        )
      end

      def serialized_record_to_event(record)
        metadata           = serializer.load(record.metadata)
        crypto_description = Hash(metadata.delete(:encryption))

        Object.const_get(record.event_type).new(
          event_id: record.event_id,
          data: decrypt_data(serializer.load(record.data), crypto_description),
          metadata: metadata,
        )
      end

      private
      attr_reader :key_repository, :serializer, :forgotten_data

      def encryption_schema(event)
        event.class.respond_to?(:encryption_schema) ? event.class.encryption_schema : {}
      end

      def deep_dup(hash)
        duplicate = hash.dup
        duplicate.each do |k, v|
          duplicate[k] = v.instance_of?(Hash) ? deep_dup(v) : v
        end
        duplicate
      end

      def encryption_metadata(data, schema)
        schema.inject({}) do |acc, (key, value)|
          case value
          when Hash
            acc[key] = encryption_metadata(data, value)
          when Proc
            key_identifier = value.call(data)
            encryption_key = key_repository.key_of(key_identifier) or raise MissingEncryptionKey.new(key_identifier)
            acc[key] = {
              cipher: encryption_key.cipher,
              iv: encryption_key.random_iv,
              identifier: key_identifier,
            }
          end
          acc
        end
      end

      def encrypt_data(data, meta)
        meta.reduce(data) do |acc, (key, value)|
          acc[key] = encrypt_attribute(acc, key, value)
          acc
        end
      end

      def decrypt_data(data, meta)
        meta.reduce(data) do |acc, (key, value)|
          acc[key] = decrypt_attribute(data, key, value)
          acc
        end
      end

      def encrypt_attribute(data, attribute, meta)
        case meta
        when Leaf
          value = data.fetch(attribute)
          return unless value

          encryption_key = key_repository.key_of(meta.fetch(:identifier))
          encryption_key.encrypt(serializer.dump(value), meta.fetch(:iv))
        when Hash
          encrypt_data(data.fetch(attribute), meta)
        end
      end

      def decrypt_attribute(data, attribute, meta)
        case meta
        when Leaf
          cryptogram = data.fetch(attribute)
          return unless cryptogram

          encryption_key = key_repository.key_of(meta.fetch(:identifier), cipher: meta.fetch(:cipher)) or return forgotten_data
          serializer.load(encryption_key.decrypt(cryptogram, meta.fetch(:iv)))
        when Hash
          decrypt_data(data.fetch(attribute), meta)
        end
      rescue OpenSSL::Cipher::CipherError
        forgotten_data
      end
    end
  end
end