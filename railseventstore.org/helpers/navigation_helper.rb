# frozen_string_literal: true

module NavigationHelper
  def top_navigation_links(version)
    [
      ["Documentation", docs_path(version)],
      ["Community", community_path],
      ["Support", support_path],
      ["Changelog", changelog_url]
    ]
  end
end
