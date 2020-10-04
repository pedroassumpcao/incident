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

config :logger, level: :error
