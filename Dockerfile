FROM elixir:1.18.4 AS build

RUN apk add --no-cache build-base npm git python3

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

COPY expense_tracker_api/mix.exs expense_tracker_api/mix.lock ./

ENV MIX_ENV=prod

RUN mix deps.get --only prod
RUN mix deps.compile

COPY expense_tracker_api/ .

RUN mix compile

RUN mix release

FROM alpine:3.18 AS app

RUN apk add --no-cache openssl ncurses-libs

RUN adduser -D -s /bin/sh app

WORKDIR /app

COPY --from=build --chown=app:app /app/_build/prod/rel/expense_tracker_api ./

USER app

EXPOSE 4000

CMD ["./bin/expense_tracker_api", "start"]