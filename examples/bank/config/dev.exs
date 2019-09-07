use Mix.Config

config :bank, Bank.EventStoreRepo, url: "ecto://postgres:postgres@localhost/bank_event_store_dev"

config :bank, Bank.ProjectionStoreRepo, url: "ecto://postgres:postgres@localhost/bank_projection_store_dev"

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
