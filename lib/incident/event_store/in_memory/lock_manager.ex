defmodule Incident.EventStore.InMemory.LockManager do
  @moduledoc """
  Manages aggregate locks for the InMemory adapter.

  The Lock Manager can be configured during initialization for the retry logic and lock timeout.
  """

  use GenServer

  alias Incident.EventStore.InMemory.AggregateLock

  @type config :: keyword()
  @type aggregate_id :: String.t()
  @type lock_acquisition_response :: :ok | {:error, :already_locked | :failed_to_lock}

  @default_timeout_ms 2_000
  @default_retries 5
  @default_jitter_range_ms 100..1000

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts \\ []) do
    config = [
      timeout_ms: Keyword.get(opts, :timeout_ms, @default_timeout_ms),
      retries: Keyword.get(opts, :retries, @default_retries),
      jitter_range_ms: Keyword.get(opts, :jitter_range_ms, @default_jitter_range_ms)
    ]

    GenServer.start_link(__MODULE__, %{config: config, locks: []}, name: __MODULE__)
  end

  @doc """
  Attempts to acquire a lock for the aggregate id.
  It uses the lock manager configuration for retry logic. In case the lock can't be acquired after all
  retry attempts, it will return an error.
  """
  @spec acquire_lock(aggregate_id()) :: lock_acquisition_response()
  def acquire_lock(aggregate_id) do
    GenServer.call(__MODULE__, {:acquire_lock, aggregate_id})
  end

  @doc """
  Removes the lock for the aggregate id that belongs to the caller.
  """
  @spec release_lock(aggregate_id()) :: :ok
  def release_lock(aggregate_id) do
    GenServer.call(__MODULE__, {:release_lock, aggregate_id})
  end

  @impl GenServer
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl GenServer
  def handle_call({:acquire_lock, aggregate_id}, {owner, _ref}, %{config: config} = state) do
    {reply, new_state} =
      case do_acquire_lock(aggregate_id, owner, state, config[:retries]) do
        {:ok, new_state} ->
          schedule_auto_release_lock(aggregate_id, config[:timeout_ms])
          {:ok, new_state}

        error ->
          error
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
  def handle_info({:auto_release_lock, aggregate_id}, %{locks: locks} = state) do
    updated_locks = Enum.reject(locks, &(&1.aggregate_id == aggregate_id))
    new_state = %{state | locks: updated_locks}

    {:noreply, new_state}
  end

  @spec do_acquire_lock(aggregate_id(), pid(), map(), non_neg_integer(), lock_acquisition_response()) ::
          {lock_acquisition_response(), map()}
  defp do_acquire_lock(aggregate_id, owner, state, retries, reply \\ {:error, :failed_to_lock})

  defp do_acquire_lock(_aggregate_id, _owner, state, retries, reply) when retries <= 0, do: {reply, state}

  defp do_acquire_lock(aggregate_id, owner, %{config: config, locks: locks} = state, retries, _reply) do
    if config[:retries] > retries do
      config[:jitter_range_ms]
      |> Enum.random()
      |> :timer.sleep()
    end

    now = DateTime.utc_now()

    locks
    |> Enum.find(fn lock ->
      lock.aggregate_id == aggregate_id && DateTime.compare(lock.valid_until, now) == :gt
    end)
    |> case do
      nil ->
        valid_until = DateTime.add(now, config[:timeout_ms], :millisecond)
        lock = %AggregateLock{aggregate_id: aggregate_id, owner_id: :erlang.phash2(owner), valid_until: valid_until}

        {:ok, %{state | locks: [lock | locks]}}

      _lock ->
        do_acquire_lock(aggregate_id, owner, state, retries - 1, {:error, :already_locked})
    end
  end

  @spec schedule_auto_release_lock(aggregate_id(), pos_integer()) :: reference()
  defp schedule_auto_release_lock(aggregate_id, interval) do
    Process.send_after(self(), {:auto_release_lock, aggregate_id}, interval)
  end
end
