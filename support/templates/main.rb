require "erb"
require "psych"

name = "aggregate_root"
ruby = %w[ruby-3.1 ruby-3.0 ruby-2.7]
gemfile = %w[Gemfile]

mk_matrix =
  lambda do |pairs|
    pairs
      .map { |name, values| values.map { |value| { name.to_s => value } } }
      .reduce(&:product)
      .map { |set| set.reduce(&:merge) }
  end

mk_indented_yaml =
  lambda do |shit, indent|
    Psych.dump(shit).lines.drop(1).join(" " * indent).strip
  end

puts ERB.new(DATA.read).result_with_hash(
       {
         name: name,
         working_directory: name,
         matrix: mk_matrix.call(ruby: ruby, gemfile: gemfile)
       }
     )

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
