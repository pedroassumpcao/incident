use Mix.Config

config :bank, ecto_repos: [Bank.EventStoreRepo, Bank.ProjectionStoreRepo]

config :incident, :event_store,
  adapter: Incident.EventStore.Postgres.Adapter,
  options: [
    repo: Bank.EventStoreRepo
  ]

config :incident, :projection_store,
  adapter: Incident.ProjectionStore.Postgres.Adapter,
  options: [
    repo: Bank.ProjectionStoreRepo
  ]

import_config "#{Mix.env()}.exs"
