defmodule Incident do
  @moduledoc false

  use Supervisor

  alias Incident.{EventStore, ProjectionStore}

  @doc """
  Starts an instance of Incident with an Incident supervisor.
  """
  def start_link(config) do
    config = %{
      event_store: [adapter: event_store_adapter(config), options: event_store_options(config)],
      projection_store: [
        adapter: projection_store_adapter(config),
        options: projection_store_options(config)
      ]
    }

    Supervisor.start_link(__MODULE__, config, name: Incident.Supervisor)
  end

  @impl true
  def init(%{event_store: event_store, projection_store: projection_store}) do
    children = [
      {EventStore, event_store},
      {ProjectionStore, projection_store}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec event_store_adapter(keyword()) :: module() | no_return()
  defp event_store_adapter(config) do
    case Keyword.get(config, :event_store) do
      :postgres ->
        EventStore.Postgres.Adapter

      :in_memory ->
        EventStore.InMemory.Adapter

      _ ->
        raise ArgumentError,
              "An Event Store adapter is required in the config. The options are :postgres and :in_memory."
    end
  end

  @spec event_store_options(keyword()) :: keyword() | no_return()
  defp event_store_options(config) do
    case Keyword.get(config, :event_store_options) do
      nil ->
        raise ArgumentError, "An Event Store Options is required based on the adapter chosen."

      options ->
        options
    end
  end

  @spec projection_store_adapter(keyword()) :: module() | no_return()
  defp projection_store_adapter(config) do
    case Keyword.get(config, :projection_store) do
      :postgres ->
        ProjectionStore.Postgres.Adapter

      :in_memory ->
        ProjectionStore.InMemory.Adapter

      _ ->
        raise ArgumentError,
              "A Projection Store adapter is required in the config. The options are :postgres and :in_memory."
    end
  end

  @spec projection_store_options(keyword()) :: keyword() | no_return()
  defp projection_store_options(config) do
    case Keyword.get(config, :projection_store_options) do
      nil ->
        raise ArgumentError, "A Projection Store Options is required based on the adapter chosen."

      options ->
        options
    end
  end
end
