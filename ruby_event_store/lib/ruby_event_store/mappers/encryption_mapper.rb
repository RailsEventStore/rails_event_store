# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class EncryptionMapper < PipelineMapper
      def initialize(key_repository, serializer: Serializers::YAML, forgotten_data: ForgottenData.new)
        super(
          Pipeline.new(
            Transformation::Encryption.new(key_repository, serializer: serializer, forgotten_data: forgotten_data),
            Transformation::SymbolizeMetadataKeys.new,
          ),
        )
      end
    end
  end
end
