use Mix.Config

config :bank, Bank.EventStoreRepo, url: "ecto://postgres:postgres@localhost/bank_event_store_test"

config :bank, Bank.ProjectionStoreRepo, url: "ecto://postgres:postgres@localhost/bank_projection_store_test"

config :incident, :event_store,
  adapter: Incident.EventStore.InMemoryAdapter,
  options: [
    initial_state: []
  ]

config :incident, :projection_store,
  adapter: Incident.ProjectionStore.InMemoryAdapter,
  options: [
    initial_state: %{Bank.Projections.BankAccount => []}
  ]
