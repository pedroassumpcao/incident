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

  def acquire_lock(server, aggregate_id, timeout_ms \\ nil) do
    GenServer.call(server, {:acquire_lock, aggregate_id, timeout_ms})
  end

  def release_lock(server, aggregate_id) do
    GenServer.call(server, {:release_lock, aggregate_id})
  end

  @impl GenServer
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl GenServer
  def handle_call(
        {:acquire_lock, aggregate_id, timeout_ms},
        {owner, _ref},
        %{config: config, locks: locks} = state
      ) do
    now = DateTime.utc_now()
    timeout = timeout_ms || config[:timeout_ms]
    valid_until = DateTime.add(now, timeout, :millisecond)

    {reply, new_state} =
      locks
      |> Enum.find(fn lock ->
        lock.aggregate_id == aggregate_id && DateTime.compare(lock.valid_until, now) == :gt
      end)
      |> case do
        nil ->
          owner_id = :erlang.phash2(owner)
          lock = %Lock{aggregate_id: aggregate_id, owner_id: owner_id, valid_until: valid_until}

          schedule_release_lock(aggregate_id, timeout)

          {:ok, %{state | locks: [lock | locks]}}

        _lock ->
          {{:error, :already_locked}, state}
      end

    {:reply, reply, new_state}
  end

  @impl GenServer
  def handle_call({:release_lock, aggregate_id}, {owner, _ref}, %{locks: locks} = state) do
    owner_id = :erlang.phash2(owner)

    updated_locks = Enum.reject(locks, &(&1.aggregate_id == aggregate_id && &1.owner_id == owner_id))

    new_state = %{state | locks: updated_locks}

    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_info({:remove_lock, aggregate_id}, %{locks: locks} = state) do
    updated_locks = Enum.reject(locks, &(&1.aggregate_id == aggregate_id))
    new_state = %{state | locks: updated_locks}

    {:noreply, new_state}
  end

  defp schedule_release_lock(aggregate_id, interval) do
    Process.send_after(self(), {:remove_lock, aggregate_id}, interval)
  end
end
