require "erb"
require "psych"

RUBY_VERSIONS = %w[ruby-3.2 ruby-3.1 ruby-3.0 ruby-2.7 truffleruby]
RAILS_GEMFILES = %w[Gemfile Gemfile.rails_6_1 Gemfile.rails_6_0]
RACK_GEMFILES = %w[Gemfile Gemfile.rack_2_0]
GEMFILES = %w[Gemfile]

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

[
  {
    name: "aggregate_root",
    matrix: mk_matrix.call(ruby: RUBY_VERSIONS, gemfile: GEMFILES)
  },
  {
    name: "ruby_event_store",
    matrix: mk_matrix.call(ruby: RUBY_VERSIONS, gemfile: GEMFILES)
  },
  {
    name: "ruby_event_store-rspec",
    matrix: mk_matrix.call(ruby: RUBY_VERSIONS, gemfile: GEMFILES)
  },
  {
    name: "ruby_event_store-browser",
    matrix:
      mk_matrix.call(ruby: RUBY_VERSIONS, gemfile: RACK_GEMFILES)
  },
  {
    name: "rails_event_store",
    matrix:
      mk_matrix.call(
        ruby: RUBY_VERSIONS,
        gemfile: RAILS_GEMFILES
      )
  },
  {
    name: "ruby_event_store-active_record",
    matrix:
      mk_matrix.call(
        ruby: RUBY_VERSIONS,
        gemfile: RAILS_GEMFILES,
        database: %w[
          sqlite3:db.sqlite3
          postgres://postgres:secret@localhost:10011/rails_event_store?pool=5
          postgres://postgres:secret@localhost:10012/rails_event_store?pool=5
          mysql2://root:secret@127.0.0.1:10008/rails_event_store?pool=5
        ],
        datatype: %w[binary json jsonb]
      )
  }
].each do |gem|
  name, matrix = gem.values_at(:name, :matrix)

  File.write(File.join(__dir__, "../../.github/workflows/#{name}.yml"), ERB.new(File.read(File.join(__dir__, "res_gem.yaml.erb"))).result_with_hash(
    name: name,
    working_directory: name,
    matrix: mk_indented_yaml[matrix, 10]
  ))

  print "."
end

puts