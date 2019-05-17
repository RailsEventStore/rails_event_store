module RubyEventStore
  module Mappers
    class EncryptionMapper < PipelineMapper
      def initialize(key_repository, serializer: YAML, forgotten_data: ForgottenData.new)
        super(Pipeline.new(
          transformations: [
            Encryption.new(key_repository, serializer: serializer, forgotten_data: forgotten_data),
            SerializationMapper.new(serializer: serializer),
          ]
        ))
      end
    end
  end
end
