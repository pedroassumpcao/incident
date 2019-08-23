defmodule Incident.EventStore.PostgresAdapter do
  @moduledoc """
  Implements an Event Store using Postgres through Ecto.
  """

  @behaviour Incident.EventStore.Adapter

  use GenServer

  alias Incident.Event.PersistedEvent
  alias Incident.EventStore.Ecto.Query

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(opts) do
    {:ok, opts}
  end

  @impl GenServer
  def handle_call(:repo, _from, [repo: repo] = state) do
    {:reply, repo, state}
  end

  @impl Incident.EventStore.Adapter
  def get(aggregate_id) do
    aggregate_id
    |> Query.get()
    |> repo().all()
  end

  @impl Incident.EventStore.Adapter
  def append(_event) do
    {:ok, %PersistedEvent{}}
  end

  @spec repo :: module()
  defp repo do
    GenServer.call(__MODULE__, :repo)
  end
end
