module RailsEventStore
  class Command
    class ValidationError < StandardError
      def initialize(errors)
        @errors = errors
      end
      attr_accessor :errors
    end

    include ActiveModel::Model
    include ActiveModel::Validations

    def validate!
      raise ValidationError.new(errors) unless valid?
    end
  end
end
