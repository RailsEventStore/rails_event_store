# Releasing RailsEventStore

Maintainer's guide for releasing RailsEventStore and related gems. Hopefully you'll know the drill after reading this.

## Versioning policy

We're following [Semantic Versioning](http://semver.org/#semantic-versioning-200). Reminder that until v1.0.0 is released:

> Anything may change at any time. The public API should not be considered stable.

We're making our best to describe and communicate breaking changes if such happen.

All gems developed in RailsEventStore monorepo will be released with the same version number, even if changes affected only a subset of gems. This is close to the versioning policy of Rails. We do this for [convenience](https://blog.arkency.com/why-we-follow-rails-repo-structure-in-rails-event-store/) not only of maintainers but also to help triaging issues related to particular version.

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

When describing changes, list all gems involved gems in the release. Explicitly mention no changes if there were none:

* no changes

When in doubt, check this [example](https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.18.0)

## Release steps

1. Draft a [new release](https://github.com/RailsEventStore/rails_event_store/releases/new) if that hasn't happened already but don't publish it yet. Leave _Tag version_ field empty by now.
2. Make sure all changes are listed on [releases page](https://github.com/RailsEventStore/rails_event_store/releases) for undrafted release. When in doubt, use [compare view](https://github.com/RailsEventStore/rails_event_store/compare/v1.1.1...master) since last release to HEAD of master branch (you may need to modify URL for correct versions to compare).
3. Bump the version number for all gems and dependencies via `make set-version RES_VERSION=version_number_here`.
4. Hit `make release` from top-level of repository. This will:
  - check of any uncommitted changes
  - run unit tests for all involved gems
  - tag last commit with version number, ending with a push to to the remote
  - build all gem packages
  - push built gem packages to RubyGems

    You'll need to have [dev_arkency](https://github.com/RailsEventStore/rails_event_store/commit/020a384b93496f0c2ba2357ec933251e8a5ed24d) RubyGems API key to complete this step.

5. Go back to [releases](https://github.com/RailsEventStore/rails_event_store/releases/), link to appropriate git tag in _Tag version_ field. Set title corresponding to version number and publish this release entry.

### Opening work on new release soon after

Draft a [new release](https://github.com/RailsEventStore/rails_event_store/releases/new) to start acquiring changelogs with each issue closed, pull-request merge and code committed. It helps much if there's a template ready to be filled.


### Troubleshooting when something went wrong during release

- no `dev@arkency.com` RubyGems credentials

  In order push gems, you have to have following `~/.gem/credentials`:

  ```yaml
  ---
  :dev_arkency: SECRET_API_KEY_FROM_RUBYGEMS_ORG
  ```

  Assuming you've by now obtained the missing credentials you can resume broken `make release` by executing last step of it explicitly, that is `make push`.
