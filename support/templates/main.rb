require "bundler/inline"
require "erb"
require "psych"

gemfile do
  source "https://rubygems.org"
  gem "szczupac", ">= 0.3.0"
end

RUBY_VERSIONS = %w[ruby-3.2 ruby-3.1 ruby-3.0 ruby-2.7 truffleruby]
RAILS_GEMFILES = %w[Gemfile Gemfile.rails_6_1 Gemfile.rails_6_0]
RACK_GEMFILES = %w[Gemfile Gemfile.rack_2_0]
GEMFILES = %w[Gemfile]
DATA_TYPES = %w[binary json jsonb]
DATABASE_URLS = %w[
  sqlite3:db.sqlite3
  postgres://postgres:secret@localhost:10012/rails_event_store?pool=5
  postgres://postgres:secret@localhost:10011/rails_event_store?pool=5
  mysql2://root:secret@127.0.0.1:10008/rails_event_store?pool=5
  mysql2://root:secret@127.0.0.1:10005/rails_event_store?pool=5
]

mk_matrix = ->(**pairs) do
  Szczupac[**pairs].map { |pair| pair.transform_keys(&:to_s) }
end

[
  {
    name: "aggregate_root",
    matrix: mk_matrix[ruby: RUBY_VERSIONS, gemfile: GEMFILES],
    template: "ruby.yaml.erb"
  },
  {
    name: "ruby_event_store",
    matrix: mk_matrix[ruby: RUBY_VERSIONS, gemfile: GEMFILES],
    template: "ruby.yaml.erb"
  },
  {
    name: "ruby_event_store-rspec",
    matrix: mk_matrix[ruby: RUBY_VERSIONS, gemfile: GEMFILES],
    template: "ruby.yaml.erb"
  },
  {
    name: "ruby_event_store-browser",
    matrix: mk_matrix[ruby: RUBY_VERSIONS, gemfile: RACK_GEMFILES],
    template: "elm.yaml.erb"
  },
  {
    name: "rails_event_store",
    matrix: mk_matrix[ruby: RUBY_VERSIONS, gemfile: RAILS_GEMFILES],
    template: "ruby.yaml.erb"
  },
  {
    name: "ruby_event_store-active_record",
    matrix:
      mk_matrix[
        ruby: RUBY_VERSIONS,
        gemfile: GEMFILES,
        database: DATABASE_URLS,
        datatype: DATA_TYPES
      ],
    template: "db.yaml.erb"
  }
].each do |gem|
  name, matrix, template = gem.values_at(:name, :matrix, :template)

  File.write(
    File.join(__dir__, "../../.github/workflows/#{name}.yml"),
    ERB.new(File.read(File.join(__dir__, template))).result_with_hash(
      name: name,
      working_directory: name,
      matrix:   Psych.dump(matrix).lines.drop(1).join(" " * 10).strip
    )
  )

  print "."
end

puts
