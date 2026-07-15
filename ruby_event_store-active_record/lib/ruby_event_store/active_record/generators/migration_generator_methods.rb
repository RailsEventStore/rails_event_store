# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    module MigrationGeneratorMethods
      private

      def absolute_path(path)
        File.expand_path(path, __dir__)
      end

      def migration_template(template_root, name)
        ERB.new(File.read(File.join(template_root, "#{name}_template.erb")))
      end

      def template_root(database_adapter)
        absolute_path("./templates/#{database_adapter.template_directory}")
      end

      def migration_version
        ::ActiveRecord::Migration.current_version
      end

      def timestamp(time = Time.now)
        time.strftime("%Y%m%d%H%M%S")
      end
    end
  end
end
