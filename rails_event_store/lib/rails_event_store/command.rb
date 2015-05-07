module RailsEventStore
  class Command
    ValidationError = Class.new(StandardError)

    include ActiveModel::Validations

    def validate!
      raise ValidationError unless valid?
    end
  end
end
