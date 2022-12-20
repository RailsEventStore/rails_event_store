module TableOfContentsHelper
  def table_of_contents
    content_without_frontmatter = File.readlines(current_page.source_file).drop(3).join("\n")
    Redcarpet::Markdown.new(Redcarpet::Render::HTML_TOC.new()).render(content_without_frontmatter)
  end
end
