use Mix.Config

config :bank, Bank.EventStoreRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "bank_event_store_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :bank, Bank.ProjectionStoreRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "bank_projection_store_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :incident, :event_store,
  adapter: Incident.EventStore.InMemoryAdapter,
  options: [
    initial_state: []
  ]

config :incident, :projection_store,
  adapter: Incident.ProjectionStore.InMemoryAdapter,
  options: [
    initial_state: %{Bank.Projections.BankAccount => [], Bank.Projections.Transfer => []}
  ]

config :logger, level: :error
