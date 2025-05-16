# frozen_string_literal: true

module DresRails
  # Generator for updating existing files.
  class UpgradeGenerator < Rails::Generators::Base
    source_root File.join(File.dirname(__FILE__), "..", "templates")

    desc "Upgrades previously installed Dres Rails resources."
    def upgrade
    end
  end
end
