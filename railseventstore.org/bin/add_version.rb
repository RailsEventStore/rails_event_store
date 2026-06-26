require "json"

def keep_only_latest_per_major(versions)
  versions
    .group_by { |v| Gem::Version.new(v).segments.first }
    .transform_values { |vs| vs.max_by { |v| Gem::Version.new(v) } }
    .values
    .sort_by { |v| Gem::Version.new(v) }
    .reverse
end

version = ARGV.fetch(0)
file = File.join(__dir__, "..", "versions.json")
versions = JSON.parse(File.read(file))
versions.unshift(version)
versions = keep_only_latest_per_major(versions)
File.write(file, JSON.pretty_generate(versions) + "\n")
