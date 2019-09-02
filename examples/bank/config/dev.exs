use Mix.Config

config :bank, Bank.EventStoreRepo, url: "ecto://postgres:postgres@localhost/bank_dev"

config :incident, :event_store, adapter: Incident.EventStore.PostgresAdapter, options: [
  repo: Bank.EventStoreRepo
]

config :incident, :projection_store, adapter: Incident.ProjectionStore.InMemoryAdapter,
  options: [
    initial_state: %{Bank.Projections.BankAccount => []}
]
