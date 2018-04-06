# frozen_string_literal: true

module DresRails
  # Generator for installing new files.
  class InstallGenerator < Rails::Generators::Base
    source_root File.join(File.dirname(__FILE__), "..", "templates")

    desc "Installs additional Dres Rails resources."
    def install
    end
  end
end
