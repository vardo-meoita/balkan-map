FROM ruby:slim AS base

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libjemalloc2 curl && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV APP_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git pkg-config libyaml-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

FROM base

RUN groupadd --system --gid 1000 app && \
    useradd app --uid 1000 --gid 1000 --create-home --shell /bin/bash

COPY --chown=app:app --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=app:app --from=build /app /app
USER 1000:1000

EXPOSE 4567
HEALTHCHECK --start-period=10s --interval=5m --start-interval=5s --timeout=3s \
    CMD curl -fSs http://127.0.0.1:4567/health

CMD ["bundle", "exec", "ruby", "/app/app.rb", "/app/static-archive"]
