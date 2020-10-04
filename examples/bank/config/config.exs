use Mix.Config

config :bank, ecto_repos: [Bank.EventStoreRepo, Bank.ProjectionStoreRepo]

config :incident, :event_store,
  adapter: Incident.EventStore.PostgresAdapter,
  options: [
    repo: Bank.EventStoreRepo
  ]

config :incident, :projection_store,
  adapter: Incident.ProjectionStore.PostgresAdapter,
  options: [
    repo: Bank.ProjectionStoreRepo
  ]

import_config "#{Mix.env()}.exs"
