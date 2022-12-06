# frozen_string_literal: true

module DocumentationHelper
  def current_source_file
    current_page.source_file.gsub(Dir.pwd, "")
  end

  def current_source_file_name
    File.basename(current_source_file)
  end

  def page_title
    current_page.data.title
  end

  def rubydoc_link(gem)
    link_to gem, "https://www.rubydoc.info/gems/#{gem}"
  end

  def feedback_link
    issue_title = "Feedback on #{URI.encode_www_form_component(page_title || current_source_file_name)}"
    link_to "Provide feedback for this page",
            File.join(github_url, "issues/new?labels=documentation&title=#{issue_title}"),
            class: "mr-4"
  end

  def edit_github_link
    link_to "Edit this page on GitHub",
            File.join(github_url, "blob/master/railseventstore.org", current_source_file),
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
end
