module RailsEventStore
  class Command
    class ValidationError < StandardError
      def initialize(errors)
        @errors = errors
      end
      attr_accessor :errors
    end

    include ActiveModel::Validations

    def validate!
      raise ValidationError.new(42) unless valid?
    end
  end
end
