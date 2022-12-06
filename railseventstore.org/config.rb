# frozen_string_literal: true

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
set :markdown, tables: true, autolink: true, fenced_code_blocks: true, with_toc_data: true, no_intra_emphasis: true

set :res_version_v1, "1.3.1"
set :res_version_v2, "2.6.0"
set :res_version, "2.6.0"

page "/"
page "/docs/v1/*", locals: { version: "v1" }, layout: "documentation"
page "/docs/v2/*", locals: { version: "v2" }, layout: "documentation"
page "*", locals: { version: "v2" }
