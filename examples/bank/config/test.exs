use Mix.Config

config :bank, Bank.EventStoreRepo, url: "ecto://postgres:postgres@localhost/bank_test"

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
