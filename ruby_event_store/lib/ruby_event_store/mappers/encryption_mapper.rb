module RubyEventStore
  module Mappers
    class EncryptionMapper
      include PipelineMapper

      def initialize(key_repository, serializer: YAML, forgotten_data: ForgottenData.new)
        @pipeline = Pipeline.new(
          transformations: [
            Encryption.new(key_repository, forgotten_data: forgotten_data),
            SerializationMapper.new(serializer: serializer),
          ]
        )
      end
    end
  end
end
