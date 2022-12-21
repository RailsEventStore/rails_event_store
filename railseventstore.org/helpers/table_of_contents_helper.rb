module TableOfContentsHelper
  def table_of_contents
    content_without_frontmatter = File.readlines(current_page.source_file).drop(3).join("\n")
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML_TOC.new, no_intra_emphasis: true)
    markdown.render(content_without_frontmatter)
  end
end
