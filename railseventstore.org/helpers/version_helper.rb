# frozen_string_literal: true

module VersionHelper
  def version_above(version_string)
    given_version = Gem::Version.new(version_string)
    current_version = Gem::Version.new(config[:res_version])
    current_version > given_version
  end

  def version_gteq(version_string)
    given_version = Gem::Version.new(version_string)
    current_version = Gem::Version.new(config[:res_version])
    current_version >= given_version
  end

  def in_version_above(version_string, &block)
    block.call if version_above(version_string)
  end

  def in_version_at_most(version_string, &block)
    block.call unless version_above(version_string)
  end
end
