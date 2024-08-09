# frozen_string_literal: true

require "tilt"
require "arbre"

class ArbreTemplate < ::Tilt::Template
  def prepare
  end

  def precompiled_template(locals)
    <<-END
      Arbre::Context.new(locals, self) {
        #{data}
      }.to_s
    END
  end
end

::Tilt.register(ArbreTemplate, "arb")

activate :aria_current
activate :directory_indexes
activate :syntax do |syntax|
  syntax.css_class = "syntax-highlight"
end
activate :external_pipeline,
         name: :tailwindcss,
         command: build? ? "npm run build" : "npm run watch",
         source: ".tmp/dist",
         latency: 1

set :markdown_engine, :redcarpet
set :markdown,
    tables: true,
    autolink: true,
    fenced_code_blocks: true,
    with_toc_data: true,
    no_intra_emphasis: true

set :res_version_v1, "1.3.1"
set :res_version_v2, "2.15.0"
set :res_version_v3, "3.0.0"
set :res_version, "2.15.0"

page "/"
page "/docs/v1/*", locals: { version: "v1" }, layout: "documentation"
page "/docs/v2/*", locals: { version: "v2" }, layout: "documentation"
page "*", locals: { version: "v2" }
