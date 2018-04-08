
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "postgresql_queue/version"

Gem::Specification.new do |spec|
  spec.name          = "postgresql_queue"
  spec.version       = PostgresqlQueue::VERSION
  spec.authors       = ["Robert Pankowecki", "Arkency"]
  spec.email         = ["robert.pankowecki@gmail.com", "dev@arkency.com"]

  spec.summary       = %q{Expose events from rails_event_store as queue for consumers iterating over global stream}
  spec.description   = %q{Expose events from rails_event_store as queue for consumers iterating over global stream }
  spec.homepage      = "https://blog.arkency.com"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails_event_store_active_record", ["~> 0.27", "< 0.28"]
  spec.add_dependency "pg", [">= 0.15", "< 2"]
  spec.add_dependency "rails", ["~> 5.0", "< 6"] # rails_event_store_active_record uses rails/generators :(

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "concurrent-ruby", "~> 1.0"
  spec.add_development_dependency "mutant-rspec", "~> 0.8.14"
end
