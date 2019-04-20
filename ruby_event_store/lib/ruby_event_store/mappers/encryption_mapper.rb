module RubyEventStore
  module Mappers
    class EncryptionMapper
      include PipelineMapper

      def initialize(key_repository, serializer: YAML, forgotten_data: ForgottenData.new)
        @pipeline = Pipeline.new(
          to_serialized_record: SerializedRecordMapper.new(serializer: serializer),
          transformations: Encryption.new(key_repository, forgotten_data: forgotten_data)
        )
      end
    end
  end
end
