module RailsEventStore
  def self.const_missing(const_name)
    super unless const_name == :MethodNotDefined
    warn "`RailsEventStore::MethodNotDefined` has been deprecated. Use `RailsEventStore::InvalidHandler` instead."
    InvalidHandler
  end
end
