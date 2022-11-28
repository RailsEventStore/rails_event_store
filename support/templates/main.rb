require "erb"
require "psych"

RUBY_VERSIONS = %w[ruby-3.1 ruby-3.0 ruby-2.7]

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

template = DATA.read

[
  {
    name: "aggregate_root",
    matrix: mk_matrix.call(ruby: RUBY_VERSIONS, gemfile: %w[Gemfile])
  },
  {
    name: "ruby_event_store",
    matrix: mk_matrix.call(ruby: RUBY_VERSIONS, gemfile: %w[Gemfile])
  },
  {
    name: "ruby_event_store-rspec",
    matrix: mk_matrix.call(ruby: RUBY_VERSIONS, gemfile: %w[Gemfile])
  },
  {
    name: "ruby_event_store-browser",
    matrix:
      mk_matrix.call(ruby: RUBY_VERSIONS, gemfile: %w[Gemfile Gemfile.rack_2_0])
  },
  {
    name: "rails_event_store",
    matrix:
      mk_matrix.call(
        ruby: RUBY_VERSIONS,
        gemfile: %w[Gemfile Gemfile.rails_6_1 Gemfile.rails_6_0]
      )
  },
  {
    name: "ruby_event_store-active_record",
    matrix:
      mk_matrix.call(
        ruby: RUBY_VERSIONS,
        gemfile: %w[Gemfile Gemfile.rails_6_1 Gemfile.rails_6_0],
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

  yaml =
    ERB.new(template).result_with_hash(
      name: name,
      working_directory: name,
      matrix: matrix
    )
  workflow_path = File.join(__dir__, "../../.github/workflows/#{name}.yml")

  File.write(workflow_path, yaml)

  print "."
end

puts

__END__
name: <%= name %>
on:
  repository_dispatch:
    types:
      - script
  workflow_dispatch:
  push:
    paths-ignore:
      - "railseventstore.org/**"
      - "contrib/**"
  pull_request:
    types: [opened, reopened]
    paths-ignore:
      - "railseventstore.org/**"
      - "contrib/**"
jobs:
  test:
    runs-on: ubuntu-20.04
    env:
      WORKING_DIRECTORY: <%= working_directory %>
      BUNDLE_GEMFILE: ${{ matrix.gemfile }}
    strategy:
      fail-fast: false
      matrix:
        include:
          <%= mk_indented_yaml.call(matrix, 10) %>
    steps:
      - uses: actions/checkout@v3
      - run: test -e ${{ matrix.gemfile }}.lock
        working-directory: ${{ env.WORKING_DIRECTORY }}
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby }}
          bundler-cache: true
          working-directory: ${{ env.WORKING_DIRECTORY }}
      - run: make test
        working-directory: ${{ env.WORKING_DIRECTORY }}

  mutate:
    runs-on: ubuntu-20.04
    env:
      WORKING_DIRECTORY: <%= working_directory %>
      BUNDLE_GEMFILE: Gemfile
    strategy:
      fail-fast: false
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - run: test -e ${{ env.BUNDLE_GEMFILE }}.lock
        working-directory: ${{ env.WORKING_DIRECTORY }}
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ruby-3.1
          bundler-cache: true
          working-directory: ${{ env.WORKING_DIRECTORY }}
      - run: make mutate-changes
        working-directory: ${{ env.WORKING_DIRECTORY }}
