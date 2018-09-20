activate :aria_current
activate :directory_indexes
activate :autoprefixer
activate :syntax do |syntax|
  syntax.css_class = "syntax-highlight"
end

set :markdown, tables: true, autolink: true, gh_blockcode: true, fenced_code_blocks: true, with_toc_data: true, no_intra_emphasis: true
set :markdown_engine, :redcarpet
set :res_version, File.read('../RES_VERSION')

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
end

page "/", layout: "landing"
page "/docs/*", layout: "documentation"
