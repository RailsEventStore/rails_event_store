# frozen_string_literal: true

module RubyEventStore
  module Browser
    class Layout
      def initialize(stylesheets_resolver, scripts_resolver, nav_links_resolver, views_roots:)
        @stylesheets_resolver = stylesheets_resolver
        @scripts_resolver = scripts_resolver
        @nav_links_resolver = nav_links_resolver
        @views_roots = views_roots
      end

      def with_views_root(views_root)
        Layout.new(
          @stylesheets_resolver,
          @scripts_resolver,
          @nav_links_resolver,
          views_roots: @views_roots + [views_root],
        )
      end

      def render(template, urls:, title:, **locals)
        content = renderer.render(template, urls: urls, **locals)
        [200, { "content-type" => "text/html;charset=utf-8" }, [wrap(renderer, content, urls, title)]]
      end

      def render_partial(template, urls:, **locals)
        renderer.render(template, urls: urls, **locals)
      end

      def not_found(urls, message:)
        content = renderer.render("not_found", message: message)
        [404, { "content-type" => "text/html;charset=utf-8" }, [wrap(renderer, content, urls, "Not found")]]
      end

      private

      def renderer
        Renderer.new([*@views_roots, Renderer::VIEWS_ROOT])
      end

      def wrap(renderer, content, urls, title)
        renderer.render(
          "layout",
          content: content,
          urls: urls,
          title: title,
          extension_stylesheets: @stylesheets_resolver.call(urls),
          extension_scripts: @scripts_resolver.call(urls),
          extension_nav_links: @nav_links_resolver.call(urls),
        )
      end
    end
  end
end
