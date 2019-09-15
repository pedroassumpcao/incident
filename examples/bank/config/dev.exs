use Mix.Config

config :bank, Bank.EventStoreRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "bank_event_store_dev"

config :bank, Bank.ProjectionStoreRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "bank_projection_store_dev"

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
