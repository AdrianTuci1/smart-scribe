# Build Stage
FROM elixir:latest AS build

# Install build dependencies
RUN apt-get update && apt-get install -y build-essential git \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Prepare build dir
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Set build env
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# Compile assets

COPY priv priv
COPY lib lib
COPY config config


# Compile Release
RUN mix compile
RUN mix release

# Runner Stage
FROM debian:bookworm-slim AS app
RUN apt-get update && apt-get install -y openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app

COPY --from=build /app/_build/prod/rel/voicescribe_api ./

ENV HOME=/app

CMD ["bin/voicescribe_api", "start"]
