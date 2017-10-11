# Releasing RailsEventStore

Maintainer's guide for releasing RailsEventStore and related gems. Hopefully you'll know the drill after reading this.

## Versioning policy

We're following [Semantic Versioning](http://semver.org/#semantic-versioning-200). Reminder that until v1.0.0 is released:

> Anything may change at any time. The public API should not be considered stable.

We're making our best to describe and communicate breaking changes if such happen.

All gems developed in RailsEventStore monorepo will be released with the same version number, even if changes affected only a subset of gems. This is close to the versioning policy of Rails. We do this for [convenience](http://blog.arkency.com/why-we-follow-rails-repo-structure-in-rails-event-store/) not only of maintainers but also to help triaging issues related to particular version.

## Communicating changes

All changes across RailsEventStore versions should be documented on changelog. For this purpose, since v0.15.0, we use [releases page](https://github.com/RailsEventStore/rails_event_store/releases). Some gems keep individual changelogs prior to the great monorepo merge — they're not updated anymore.

Changes are easier to scan, when they're described with following types:

* Add: for new features
* Change: for changes in existing functionality
* Deprecate: for soon-to-be removed features
* Remove: for now removed features
* Fix: for any bug fixes
* Security: in case of vulnerabilities

Use them following to the full description of introduced change.

When describing changes, list all gems involved gems in the release. Explicitly mention no changes if there were none. When in doubt, check this [example](https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.18.0)

## Release steps

#### Documenting, tagging and RubyGems push

1. Make sure all changes are listed on [releases page](https://github.com/RailsEventStore/rails_event_store/releases) for undrafted release. When in doubt, use [compare view](https://github.com/RailsEventStore/rails_event_store/compare/v0.17.0...master) since last release to HEAD of master branch.
2. Hit `make release` from top-level of repository. This will:
  - check of any uncommitted changes
  - run unit tests for all involved gems
  - tag last commit with version number, ending in a push to remote
  - loop over gems and build gem packages followed by RubyGems push for each

  You'll need to be [gem owner](https://rubygems.org/gems/rails_event_store) of each gem to complete this step.
3. Bump version number in documentation section of [railseventstore.org](https://railseventstore.org). It's good practice to list changes in [documentation](http://railseventstore.org/docs/changelog/).

#### Opening work on new release soon after

1. Bump the version number via `make set-version RES_VERSION=version_number_here`. This will be the next release version.
2. Draft [new release](https://github.com/RailsEventStore/rails_event_store/releases/new) to start acquiring changelogs with each issue closed, pull-request merge and code committed. It helps much if there's a template ready to be filled.
