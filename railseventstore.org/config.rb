require "octokit"
require "faraday"

class Stats
  def initialize
    @octokit_client = Octokit::Client.new
    @octokit_client.auto_paginate = true
  end

  def contributors
    @contributors ||= octokit_client.contributors(repo)
  end

  def stargazers_count
    octokit_client.repo(repo)[:stargazers_count]
  end

  def contributors_count
    contributors.size
  end

  def releases_count
    octokit_client.releases(repo).size
  end

  def total_downloads_count
    response =
      Faraday.get(
        "https://rubygems.org/api/v1/downloads/rails_event_store-1.0.0.json"
      )
    JSON.parse(response.body)["total_downloads"]
  end

  private

  def octokit_client
    @octokit_client
  end

  def repo
    "RailsEventStore/rails_event_store"
  end
end

$stats = Stats.new

activate :aria_current
activate :directory_indexes
activate :syntax do |syntax|
  syntax.css_class = "syntax-highlight"
end
activate :external_pipeline,
         name: :whatever,
         command: build? ? "npm run build" : "npm run watch",
         source: ".tmp/dist",
         latency: 1

set :markdown_engine, :redcarpet
set :res_version_v1, "1.3.1"
set :res_version_v2, "2.6.0"
set :res_version, "2.6.0"

set :markdown,
    tables: true,
    autolink: true,
    gh_blockcode: true,
    fenced_code_blocks: true,
    with_toc_data: true,
    no_intra_emphasis: true

helpers do
  def version_above(version_string)
    given_version = Gem::Version.new(version_string)
    current_version = Gem::Version.new(config[:res_version])
    current_version > given_version
  end

  def version_gteq(version_string)
    given_version = Gem::Version.new(version_string)
    current_version = Gem::Version.new(config[:res_version])
    current_version >= given_version
  end

  def in_version_above(version_string, &block)
    block.call if version_above(version_string)
  end

  def in_version_at_most(version_string, &block)
    block.call unless version_above(version_string)
  end

  def current_source_file
    current_page.source_file.gsub(Dir.pwd, "")
  end

  def current_source_file_name
    File.basename(current_source_file)
  end

  def github_url
    "https://github.com/RailsEventStore/rails_event_store"
  end

  def page_title
    current_page.data.title
  end

  def rubydoc_link(gem)
    link_to gem, "https://www.rubydoc.info/gems/#{gem}"
  end

  def feedback_link
    issue_title =
      "Feedback on #{URI.encode_www_form_component(page_title || current_source_file_name)}"
    link_to "Provide feedback for this page",
            File.join(
              github_url,
              "issues/new?labels=documentation&title=#{issue_title}"
            ),
            class: "mr-4"
  end

  def edit_github_link
    link_to "Edit this page on GitHub",
            File.join(
              github_url,
              "blob/master/railseventstore.org",
              current_source_file
            ),
            class: "mr-4"
  end

  def sidebar_link_to(name, url)
    current_link_to(
      name,
      url,
      class: %w[
        font-normal
        bg-none
        bg-none
        text-gray-700
        hover:text-gray-800
        hover:bg-gradient
        aria[current="page"]:font-bold
        aria[current="page"]:text-gray-800
      ]
    )
  end

  def contributors
    $stats.contributors
  end

  def contributors_count
    $stats.contributors_count
  end

  def stargazers_count
    $stats.stargazers_count
  end

  def releases_count
    $stats.releases_count
  end

  def total_downloads
    $stats.total_downloads_count
  end
end

page "/", layout: "landing"
page "/docs/v1/*", layout: "documentation", locals: { version: "v1" }
page "/docs/v2/*", layout: "documentation", locals: { version: "v2" }
page "*", locals: { version: "v2" }
