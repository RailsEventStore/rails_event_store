module RubyEventStore
  def self.const_missing(const_name)
    super unless const_name == :MethodNotDefined
    warn "`RubyEventStore::MethodNotDefined` has been deprecated. Use `RubyEventStore::InvalidHandler` instead."
    InvalidHandler
  end
end
