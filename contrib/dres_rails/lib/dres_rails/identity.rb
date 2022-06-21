# frozen_string_literal: true

module DresRails
  # Gem identity information.
  module Identity
    def self.name
      "dres_rails"
    end

    def self.label
      "Dres Rails"
    end

    def self.version
      "0.6.0"
    end

    def self.version_label
      "#{label} #{version}"
    end
  end
end
