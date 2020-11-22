defmodule Incident.EventStore.Postgres.Adapter do
  @moduledoc """
  Implements an Event Store using Postgres through Ecto.
  """

  @behaviour Incident.EventStore.Adapter

  use GenServer

  import Ecto.Query, only: [from: 2]

  alias Incident.EventStore.Postgres.Event

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(opts) do
    {:ok, opts}
  end

  @impl GenServer
  def handle_call(:repo, _from, state) do
    {:reply, state[:repo], state}
  end

  @impl Incident.EventStore.Adapter
  def get(aggregate_id) do
    query =
      from(
        e in Event,
        where: e.aggregate_id == ^aggregate_id,
        order_by: [asc: e.id]
      )

    repo().all(query)
  end

  @impl Incident.EventStore.Adapter
  def append(event) do
    new_event = %{
      event_id: Ecto.UUID.generate(),
      aggregate_id: event.aggregate_id,
      event_type: event.__struct__ |> Module.split() |> List.last(),
      version: event.version,
      event_date: DateTime.utc_now(),
      event_data: event |> Map.from_struct() |> stringify_keys()
    }

    %Event{}
    |> Event.changeset(new_event)
    |> repo().insert()
  end

  @spec repo :: module()
  defp repo do
    GenServer.call(__MODULE__, :repo)
  end

  @spec stringify_keys(map) :: map
  defp stringify_keys(enumerable) when is_map(enumerable) do
    Enum.into(enumerable, %{}, fn {k, v} -> {stringify_key(k), v} end)
  end

  @spec stringify_key(atom | String.t()) :: String.t()
  defp stringify_key(key) when is_atom(key), do: Atom.to_string(key)
  defp stringify_key(key), do: key
end
