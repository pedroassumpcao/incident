defmodule Incident.EventStore.InMemoryAdapter do
  @moduledoc """
  Implements an in-memory Event Store using Agents.
  """

  @behaviour Incident.EventStore.Adapter

  use Agent

  alias Incident.EventStore.InMemoryEvent

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts \\ []) do
    initial_state = Keyword.get(opts, :initial_state, [])

    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  @impl true
  def get(aggregate_id) do
    __MODULE__
    |> Agent.get(& &1)
    |> Enum.filter(&(&1.aggregate_id == aggregate_id))
    |> Enum.reverse()
  end

  @impl true
  def append(event) do
    persisted_event = %InMemoryEvent{
      event_id: Ecto.UUID.generate(),
      aggregate_id: event.aggregate_id,
      event_type: event.__struct__ |> Module.split() |> List.last(),
      version: event.version,
      event_date: DateTime.utc_now(),
      event_data: event |> Map.from_struct() |> stringify_keys()
    }

    Agent.update(__MODULE__, &([persisted_event] ++ &1))

    {:ok, persisted_event}
  end

  @spec stringify_keys(map) :: map
  defp stringify_keys(enumerable) when is_map(enumerable) do
    Enum.into(enumerable, %{}, fn {k, v} -> {stringify_key(k), v} end)
  end

  @spec stringify_key(atom | String.t()) :: String.t()
  defp stringify_key(key) when is_atom(key), do: Atom.to_string(key)
  defp stringify_key(key), do: key
end
