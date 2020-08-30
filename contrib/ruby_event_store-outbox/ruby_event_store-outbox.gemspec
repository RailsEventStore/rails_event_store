$:.push File.expand_path('../lib', __FILE__)

require 'ruby_event_store/outbox/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruby_event_store-outbox'
  spec.version       = RubyEventStore::Outbox::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ['Arkency']
  spec.email         = ['dev@arkency.com']

  spec.summary = %q{Active Record based outbox for Ruby Event Store}
  spec.homepage = 'https://railseventstore.org'
  spec.metadata = {
    "homepage_uri" => "https://railseventstore.org/",
    "changelog_uri" => "https://github.com/RailsEventStore/rails_event_store/releases",
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
  }

  spec.files = Dir['{bin,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  spec.bindir = 'bin'
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'ruby_event_store', '>= 1.0.0'
  spec.add_dependency 'activerecord', '>= 3.0'
end
