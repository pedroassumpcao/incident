defmodule Incident.EventStore.InMemory.LockManager do
  @moduledoc """
  Manages aggregate locks for events for the InMemory adapter.
  """

  use GenServer

  alias Incident.EventStore.InMemory.Lock

  @default_timeout_ms 2_000

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts \\ []) do
    config = [
      timeout_ms: Keyword.get(opts, :timeout_ms, @default_timeout_ms)
    ]

    GenServer.start_link(__MODULE__, %{config: config, locks: []})
  end

  def acquire_lock(server, aggregate_id, owner_id, timeout_ms \\ nil) do
    GenServer.call(server, {:acquire_lock, aggregate_id, owner_id, timeout_ms})
  end

  @impl GenServer
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl GenServer
  def handle_call(
        {:acquire_lock, aggregate_id, owner_id, nil},
        _from,
        %{config: config, locks: locks} = state
      ) do
    now = DateTime.utc_now()
    valid_until = DateTime.add(now, config[:timeout_ms], :millisecond)

    {reply, state} =
      locks
      |> Enum.find(fn lock ->
        lock.aggregate_id == aggregate_id && DateTime.compare(lock.valid_until, now) == :gt
      end)
      |> case do
        nil ->
          lock = %Lock{aggregate_id: aggregate_id, owner_id: owner_id, valid_until: valid_until}
          {:ok, %{state | locks: [lock | locks]}}

        _lock ->
          {{:error, :already_locked}, state}
      end

    {:reply, reply, state}
  end
end
