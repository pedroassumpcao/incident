defmodule Incident do
  @moduledoc false

  use Supervisor

  alias Incident.{EventStore, EventStoreSupervisor, ProjectionStore}

  @doc """
  Starts an instance of Incident with an Incident supervisor.
  """
  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: Incident.Supervisor)
  end

  @impl true
  def init(config) do
    config = %{
      event_store: %{
        adapter: event_store_adapter_for(config),
        options: event_store_options(config)
      },
      projection_store: %{
        adapter: projection_store_adapter_for(config),
        options: projection_store_options(config)
      }
    }

    children = [
      {EventStoreSupervisor, config.event_store},
      {ProjectionStore, config.projection_store}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec event_store_adapter_for(keyword()) :: module() | no_return()
  defp event_store_adapter_for(config) do
    case get_in(config, [:event_store, :adapter]) do
      :postgres ->
        EventStore.Postgres.Adapter

      :in_memory ->
        EventStore.InMemory.Adapter

      _ ->
        raise RuntimeError,
              "An Event Store adapter is required in the config. The options are :postgres and :in_memory."
    end
  end

  @spec event_store_options(keyword()) :: keyword() | no_return()
  defp event_store_options(config) do
    case get_in(config, [:event_store, :options]) do
      nil ->
        raise RuntimeError, "An Event Store Options is required based on the adapter chosen."

      options ->
        options
    end
  end

  @spec projection_store_adapter_for(keyword()) :: module() | no_return()
  defp projection_store_adapter_for(config) do
    case get_in(config, [:projection_store, :adapter]) do
      :postgres ->
        ProjectionStore.Postgres.Adapter

      :in_memory ->
        ProjectionStore.InMemory.Adapter

      _ ->
        raise RuntimeError,
              "A Projection Store adapter is required in the config. The options are :postgres and :in_memory."
    end
  end

  @spec projection_store_options(keyword()) :: keyword() | no_return()
  defp projection_store_options(config) do
    case get_in(config, [:projection_store, :options]) do
      nil ->
        raise RuntimeError, "A Projection Store Options is required based on the adapter chosen."

      options ->
        options
    end
  end
end
