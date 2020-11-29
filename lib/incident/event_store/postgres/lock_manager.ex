defmodule Incident.EventStore.Postgres.LockManager do
  @moduledoc """
  Manages aggregate locks for events for the Postgres adapter.
  """

  use GenServer

  import Ecto.Query, only: [from: 2]

  alias Ecto.Multi
  alias Incident.EventStore.Postgres.{Adapter, AggregateLock}

  @type config :: keyword()
  @type aggregate_id :: String.t()
  @type lock_acquisition_response :: :ok | {:error, :already_locked | :failed_to_lock}

  @default_timeout_ms 2_000
  @default_retries 5
  @default_jitter_range_ms 100..1000

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    config = [
      timeout_ms: Keyword.get(opts, :timeout_ms, @default_timeout_ms),
      retries: Keyword.get(opts, :retries, @default_retries),
      jitter_range_ms: Keyword.get(opts, :jitter_range_ms, @default_jitter_range_ms)
    ]

    GenServer.start_link(__MODULE__, %{config: config})
  end

  @spec acquire_lock(pid(), aggregate_id()) :: lock_acquisition_response()
  def acquire_lock(server, aggregate_id) do
    GenServer.call(server, {:acquire_lock, aggregate_id})
  end

  @spec release_lock(pid(), aggregate_id()) :: :ok
  def release_lock(server, aggregate_id) do
    GenServer.call(server, {:release_lock, aggregate_id})
  end

  @impl GenServer
  def init(config) do
    {:ok, config}
  end

  @impl GenServer
  def handle_call({:acquire_lock, aggregate_id}, {owner, _ref}, %{config: config} = state) do
    reply =
      case do_acquire_lock(aggregate_id, owner, config, config[:retries]) do
        :ok ->
          schedule_auto_release_lock(aggregate_id, config[:timeout_ms])
          :ok

        error ->
          error
      end

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_call({:release_lock, aggregate_id}, {owner, _ref}, state) do
    owner_id = :erlang.phash2(owner)

    query =
      from(
        al in AggregateLock,
        where: al.aggregate_id == ^aggregate_id,
        where: al.owner_id == ^owner_id
      )

    Adapter.repo().delete_all(query)

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info({:auto_release_lock, aggregate_id}, state) do
    query =
      from(
        al in AggregateLock,
        where: al.aggregate_id == ^aggregate_id
      )

    Adapter.repo().delete_all(query)

    {:noreply, state}
  end

  @spec do_acquire_lock(aggregate_id(), pid(), config(), non_neg_integer(), lock_acquisition_response()) ::
          lock_acquisition_response()
  defp do_acquire_lock(aggregate_id, owner, config, retries, reply \\ {:error, :failed_to_lock})

  defp do_acquire_lock(_aggregate_id, _owner, _config, retries, reply) when retries <= 0, do: reply

  defp do_acquire_lock(aggregate_id, owner, config, retries, _reply) do
    if config[:retries] > retries do
      config[:jitter_range_ms]
      |> Enum.random()
      |> :timer.sleep()
    end

    Multi.new()
    |> Multi.run(:changeset, fn repo, _ ->
      now = DateTime.utc_now()

      query =
        from(
          al in AggregateLock,
          where: al.aggregate_id == ^aggregate_id,
          where: al.valid_until > ^now,
          limit: 1,
          lock: "FOR UPDATE"
        )

      case repo.one(query) do
        nil ->
          valid_until = DateTime.add(now, config[:timeout_ms], :millisecond)

          changeset =
            AggregateLock.changeset(%AggregateLock{}, %{
              aggregate_id: aggregate_id,
              owner_id: :erlang.phash2(owner),
              valid_until: valid_until
            })

          {:ok, changeset}

        _lock ->
          {:error, :already_locked}
      end
    end)
    |> Multi.run(:lock, fn repo, %{changeset: changeset} ->
      repo.insert(changeset)
    end)
    |> Adapter.repo().transaction()
    |> case do
      {:ok, _} ->
        :ok

      {:error, :changeset, _, _} ->
        do_acquire_lock(aggregate_id, owner, config, retries - 1, {:error, :already_locked})

      {:error, _, _, _} ->
        do_acquire_lock(aggregate_id, owner, config, retries - 1, {:error, :failed_to_lock})
    end
  end

  @spec schedule_auto_release_lock(aggregate_id(), pos_integer()) :: reference()
  defp schedule_auto_release_lock(aggregate_id, interval) do
    Process.send_after(self(), {:auto_release_lock, aggregate_id}, interval)
  end
end
