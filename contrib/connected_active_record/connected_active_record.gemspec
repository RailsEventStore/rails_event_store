lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "connected_active_record/version"

Gem::Specification.new do |spec|
  spec.name          = "connected_active_record"
  spec.version       = ConnectedActiveRecord::VERSION
  spec.authors       = ["Mirosław Pragłowski"]
  spec.email         = ["m@praglowski.com"]

  spec.summary       = %q{EventRepository wrapper to allow easy use of
    https://guides.rubyonrails.org/active_record_multiple_databases.html}

  spec.add_dependency "activerecord", ">= 6"
  spec.add_dependency "ruby_event_store"
  spec.add_dependency "rails_event_store_active_record"

  spec.add_development_dependency "rspec-rails"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end