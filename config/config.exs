use Mix.Config

config :incident, :event_store,
  adapter: Incident.EventStore.InMemoryAdapter,
  options: %{
    initial_state: []
  }

config :incident, :projection_store,
  adapter: Incident.ProjectionStore.InMemoryAdapter,
  options: %{
    initial_state: %{}
  }
