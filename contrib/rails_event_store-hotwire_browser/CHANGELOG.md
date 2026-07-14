### 0.1.0

- Add: Initial release. Server-rendered event browser for RailsEventStore, mounted as a Rails engine (`RailsEventStore::HotwireBrowser::Engine`) and rendered with Hotwire (Stimulus, no Turbo). Reads events straight from `Rails.configuration.event_store` — no JSON:API layer.
- Add: Stream view with pagination and event view with correlation/causation navigation and raw data/metadata.
- Add: Related streams section, configurable via `config.x.rails_event_store_hotwire_browser_related_streams_query`.
- Add: Client-side timezone conversion of event timestamps.
- Add: Node-free asset pipeline — Tailwind standalone for the stylesheet, Stimulus vendored from a CDN at build time. Assets are served locally, or from `cdn.railseventstore.org` when the gem is installed from git.
