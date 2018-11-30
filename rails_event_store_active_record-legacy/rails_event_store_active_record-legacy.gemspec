
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rails_event_store_active_record/legacy/version"

Gem::Specification.new do |spec|
  spec.name          = "rails_event_store_active_record-legacy"
  spec.version       = RailsEventStoreActiveRecord::Legacy::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ['Arkency']
  spec.email         = ['dev@arkency.com']

  spec.summary       = %q{Active Record events repository for Rails Event Store}
  spec.description   = %q{Implementation of events repository based on Rails Active Record for Rails Event Store. Exists for limited backwards-compatibilty and should not be chosen for new projects.}

    spec.homepage      = 'https://railseventstore.org'
  spec.metadata    = {
    "homepage_uri" => "https://railseventstore.org/",
    "changelog_uri" => "https://github.com/RailsEventStore/rails_event_store/releases",
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
  }

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'ruby_event_store', '= 0.34.0'
  spec.add_dependency 'rails_event_store_active_record', '= 0.34.0'
  spec.add_dependency 'activesupport', '>= 3.0'
  spec.add_dependency 'activemodel', '>= 3.0'
end
