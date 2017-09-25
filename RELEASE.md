# Releasing RailsEventStore

Maintainer's guide for releasing RailsEventStore and related gems. Hopefully you'll know the drill after reading this.

## Versioning policy

We're following [Semnatic Versioning](http://semver.org/#semantic-versioning-200). Reminder that until v1.0.0 is released:

> Anything may change at any time. The public API should not be considered stable.

We're making our best to describe and communicate breaking changes if such happen.

All gems developed in RailsEventStore monorepo will be released with the same version number, even if changes affected only a subset of gems. This is close to the versioning policy of Rails. We do this for [convenience](http://blog.arkency.com/why-we-follow-rails-repo-structure-in-rails-event-store/) not only of maintainers but also to help triaging issues related to particular version.

## Communicating changes

All changes across RailsEventStore versions should be documented on changelog. For this purpose, since v0.15.0, we use [releases page](https://github.com/RailsEventStore/rails_event_store/). Some gems keep individual changelogs prior to greate monorepo merge — they're not updated anymore.

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

FIXME
