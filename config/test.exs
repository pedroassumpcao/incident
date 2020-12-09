use Mix.Config

config :incident, ecto_repos: [Incident.EventStore.TestRepo, Incident.ProjectionStore.TestRepo]

config :incident, Incident.EventStore.TestRepo,
  username: "postgres",
  password: "postgres",
  database: "incident_event_store_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/support/event_store"

config :incident, Incident.ProjectionStore.TestRepo,
  username: "postgres",
  password: "postgres",
  database: "incident_projection_store_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/support/projection_store"

config :logger, level: :error
