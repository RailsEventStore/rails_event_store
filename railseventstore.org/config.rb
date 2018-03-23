activate :aria_current
activate :directory_indexes
activate :syntax do |syntax|
  syntax.css_class = "syntax-highlight"
end

set :markdown, tables: true, autolink: true, gh_blockcode: true, fenced_code_blocks: true, with_toc_data: false
set :markdown_engine, :redcarpet

page "/", layout: "landing"
page "/docs/*", layout: "documentation"
