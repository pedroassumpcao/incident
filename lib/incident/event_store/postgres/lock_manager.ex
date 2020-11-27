defmodule Incident.EventStore.Postgres.LockManager do
  @moduledoc """
  Manages aggregate locks for events for the Postgres adapter.
  """

  use GenServer

  import Ecto.Query, only: [from: 2]

  alias Ecto.Multi
  alias Incident.EventStore.Postgres.{Adapter, AggregateLock}

  @default_timeout_ms 2_000

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts \\ []) do
    config = [
      timeout_ms: Keyword.get(opts, :timeout_ms, @default_timeout_ms)
    ]

    GenServer.start_link(__MODULE__, %{config: config})
  end

  def acquire_lock(server, aggregate_id, timeout_ms \\ nil) do
    GenServer.call(server, {:acquire_lock, aggregate_id, timeout_ms})
  end

  def release_lock(server, aggregate_id) do
    GenServer.call(server, {:release_lock, aggregate_id})
  end

  @impl GenServer
  def init(config) do
    {:ok, config}
  end

  @impl GenServer
  def handle_call({:acquire_lock, aggregate_id, timeout_ms}, {owner, _ref}, %{config: config} = state) do
    now = DateTime.utc_now()
    timeout = timeout_ms || config[:timeout_ms]

    reply =
      Multi.new()
      |> Multi.run(:changeset, fn repo, _ ->
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
            valid_until = DateTime.add(now, timeout, :millisecond)

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
          schedule_auto_release_lock(aggregate_id, timeout)
          :ok

        {:error, :changeset, _, _} ->
          {:error, :already_locked}

        {:error, _, _, _} ->
          {:error, :failed_to_lock}
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

  defp schedule_auto_release_lock(aggregate_id, interval) do
    Process.send_after(self(), {:auto_release_lock, aggregate_id}, interval)
  end
end
