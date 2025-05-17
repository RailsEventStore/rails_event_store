# frozen_string_literal: true

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "tzinfo"
  gem "tzinfo-data", "~> 1.2024.1"
end

def header
  [
    "-- This is a generated file. Do not edit.",
    "-- To regenerate it with the latest data, run:",
    "-- `make generate-timezones-map`",
    "",
    "module LinkedTimezones exposing (mapLinkedTimeZone)",
    "mapLinkedTimeZone : String -> String",
    "mapLinkedTimeZone str =",
    "  case str of",
  ]
end

def links
  TZInfo::Timezone.all_linked_zones.map { |zone| "    \"#{zone.identifier}\" -> \"#{zone.canonical_identifier}\"" }
end

def footer
  ["    _ -> str"]
end

File.write("elm/src/LinkedTimezones.elm", (header + links + footer).join("\n"))
