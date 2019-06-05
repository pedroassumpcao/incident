use Mix.Config

config :incident, :event_store, adapter: Incident.EventStore.InMemoryAdapter

config :incident, :projection_store, adapter: Incident.ProjectionStore.InMemoryAdapter
