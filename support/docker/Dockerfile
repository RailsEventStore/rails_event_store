ARG RUBY_VERSION=4.0

FROM ruby:${RUBY_VERSION}-slim AS base

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    entr \
    libpq-dev \
    postgresql-client \
    default-libmysqlclient-dev \
    libsqlite3-dev \
    pkg-config \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

ARG GEM_DIR=ruby_event_store-active_record
ENV GEM_DIR=${GEM_DIR}
ENV BUNDLE_PATH=/usr/local/bundle

FROM base AS deps

RUN bundle install --gemfile "${GEM_DIR}/Gemfile"

FROM deps AS test

ENTRYPOINT ["bash", "-c", "cd \"$GEM_DIR\" && exec bundle exec \"$@\"", "--"]
CMD ["rspec"]

FROM deps AS mutate

ENV MUTANT=1
ENTRYPOINT ["bash", "-c", "cd \"$GEM_DIR\" && exec bundle exec \"$@\"", "--"]
CMD ["mutant", "run"]

FROM deps AS app

EXPOSE 9393
ENTRYPOINT ["bash", "-c", "cd \"$GEM_DIR\" && exec bundle exec \"$@\"", "--"]
CMD ["rackup", "--host", "0.0.0.0", "--port", "9393", "devserver/config.ru"]

FROM deps AS console

ENTRYPOINT ["bash", "-c", "cd \"$GEM_DIR\" && exec bundle exec \"$@\"", "--"]
CMD ["irb"]
