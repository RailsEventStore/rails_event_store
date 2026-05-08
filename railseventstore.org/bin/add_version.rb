require "json"

version = ARGV.fetch(0)
file = File.join(__dir__, "..", "versions.json")
versions = JSON.parse(File.read(file))
versions.unshift(version)
File.write(file, JSON.pretty_generate(versions) + "\n")
