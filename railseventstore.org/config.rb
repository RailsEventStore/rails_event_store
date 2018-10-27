activate :aria_current
activate :directory_indexes
activate :syntax do |syntax|
  syntax.css_class = "syntax-highlight"
end
activate :external_pipeline,
  name: :webpack,
  command: build? ? 'yarn webpack-production' : 'yarn webpack-development',
  source: ".tmp/dist",
  latency: 1

set :markdown_engine, :redcarpet
set :res_version, File.read('../RES_VERSION')
set :markdown,
  tables: true,
  autolink: true,
  gh_blockcode: true,
  fenced_code_blocks: true,
  with_toc_data: true,
  no_intra_emphasis: true

helpers do
  def version_above(version_string)
    given_version   = Gem::Version.new(version_string)
    current_version = Gem::Version.new(config[:res_version])
    current_version > given_version
  end

  def version_gteq(version_string)
    given_version   = Gem::Version.new(version_string)
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
    current_page.source_file.gsub(Dir.pwd, '')
  end

  def current_source_file_name
    File.basename(current_source_file)
  end

  def github_url
    'https://github.com/RailsEventStore/rails_event_store'
  end

  def page_title
    current_page.data.title
  end

  def rubydoc_link(gem)
    link_to gem, "https://www.rubydoc.info/gems/#{gem}"
  end

  def feedback_link
    issue_title = "Feedback on #{URI.encode(page_title || current_source_file_name)}"
    link_to "Provide feedback", File.join(github_url, "issues/new?labels=documentation&title=#{issue_title}")
  end

  def edit_github_link
    link_to "Edit on GitHub", File.join(github_url, 'blob/master/railseventstore.org', current_source_file)
  end
end

page "/", layout: "landing"
page "/docs/*", layout: "documentation"
