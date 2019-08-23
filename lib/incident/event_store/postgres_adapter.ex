defmodule Incident.EventStore.PostgresAdapter do
  @moduledoc """
  Implements an Event Store using Postgres through Ecto.
  """

  @behaviour Incident.EventStore.Adapter

  use GenServer

  import Ecto.Query, only: [from: 2]

  alias Incident.EventStore.PostgresEvent, as: Event

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
    from(
      e in Event,
      where: e.aggregate_id == ^aggregate_id,
      order_by: [asc: e.event_date]
    )
    |> repo().all()
  end

  @impl Incident.EventStore.Adapter
  def append(_event) do
    {:ok, %Event{}}
  end

  @spec repo :: module()
  defp repo do
    GenServer.call(__MODULE__, :repo)
  end
end
