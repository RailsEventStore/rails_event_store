# frozen_string_literal: true

module RubyEventStore
  module Mappers
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
  end
end
