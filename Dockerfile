FROM hqmq/alpine-elixir:0.3

ENV MIX_ENV=prod
ADD mix.exs mix.lock ./
RUN apk add --no-cache make curl build-base && \
    mix do deps.get --only prod, deps.compile
ADD config ./config
ADD lib ./lib
ADD priv ./priv
RUN mix do compile

CMD elixir --no-halt -S mix
