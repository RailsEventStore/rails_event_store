activate :aria_current
activate :directory_indexes
activate :syntax do |syntax|
  syntax.css_class = "syntax-highlight"
end

set :markdown, tables: true, autolink: true, gh_blockcode: true, fenced_code_blocks: true, with_toc_data: true, no_intra_emphasis: true
set :markdown_engine, :redcarpet
set :res_version, File.read('../RES_VERSION')

page "/", layout: "landing"
page "/docs/*", layout: "documentation"
