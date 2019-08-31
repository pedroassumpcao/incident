use Mix.Config

config :incident, ecto_repos: [Incident.EventStore.TestRepo]

config :incident, Incident.EventStore.TestRepo,
  username: "postgres",
  password: "postgres",
  database: "incident_event_store_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/support/event_store"

config :incident, :event_store, adapter: Incident.EventStore.InMemoryAdapter

config :incident, :projection_store, adapter: Incident.ProjectionStore.InMemoryAdapter
