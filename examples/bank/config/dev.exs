use Mix.Config

config :incident, Incident.EventStore.Ecto.Repo, url: "ecto://postgres:postgres@localhost/bank_dev"

config :incident, :event_store, adapter: Incident.EventStore.PostgresAdapter, options: [
  url: "ecto://postgres:postgres@localhost/bank_dev"
]

config :incident, :projection_store, adapter: Incident.ProjectionStore.InMemoryAdapter,
  options: [
    initial_state: %{bank_accounts: []}
]
