require "erb"
require "psych"

RUBY_VERSIONS = %w[ruby-3.2 ruby-3.1 ruby-3.0 ruby-2.7 truffleruby]
RAILS_GEMFILES = %w[Gemfile Gemfile.rails_6_1 Gemfile.rails_6_0]
RACK_GEMFILES = %w[Gemfile Gemfile.rack_2_0]
GEMFILES = %w[Gemfile]
DATA_TYPES = %w[binary json jsonb]
DATABASE_URLS = %w[
  sqlite3:db.sqlite3
  postgres://postgres:secret@localhost:10011/rails_event_store?pool=5
  postgres://postgres:secret@localhost:10012/rails_event_store?pool=5
  mysql2://root:secret@127.0.0.1:10008/rails_event_store?pool=5
]

mk_matrix =
  lambda do |pairs|
    first, *rest =
      pairs.map { |name, values| values.map { |value| { name.to_s => value } } }
    first.product(*rest).map { |set| set.reduce(&:merge) }
  end

mk_indented_yaml =
  lambda do |shit, indent|
    Psych.dump(shit).lines.drop(1).join(" " * indent).strip
  end

{
  "aggregate_root" => mk_matrix[ruby: RUBY_VERSIONS, gemfile: GEMFILES],
  "ruby_event_store" => mk_matrix[ruby: RUBY_VERSIONS, gemfile: GEMFILES],
  "ruby_event_store-rspec" => mk_matrix[ruby: RUBY_VERSIONS, gemfile: GEMFILES],
  "ruby_event_store-browser" =>
    mk_matrix[ruby: RUBY_VERSIONS, gemfile: RACK_GEMFILES],
  "rails_event_store" =>
    mk_matrix[ruby: RUBY_VERSIONS, gemfile: RAILS_GEMFILES],
  "ruby_event_store-active_record" =>
    mk_matrix[
      ruby: RUBY_VERSIONS,
      gemfile: RAILS_GEMFILES,
      database: DATABASE_URLS,
      datatype: DATA_TYPES
    ]
}.each do |name, matrix|
  File.write(
    File.join(__dir__, "../../.github/workflows/#{name}.yml"),
    ERB.new(File.read(File.join(__dir__, "res_gem.yaml.erb"))).result_with_hash(
      name: name,
      working_directory: name,
      matrix: mk_indented_yaml[matrix, 10]
    )
  )

  print "."
end

puts
