use Mix.Config

config :incident, :event_store, adapter: Incident.EventStore.InMemoryAdapter, initial_state: []

config :incident, :projection_store,
  adapter: Incident.ProjectionStore.InMemoryAdapter,
  initial_state: %{}
