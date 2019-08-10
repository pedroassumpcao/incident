defmodule Incident.EventStore.PostgresAdapter do
  @moduledoc """
  Implements an Event Store using Postgres through Ecto.
  """

  @behaviour Incident.EventStore.Adapter

  alias Incident.Event.PersistedEvent
  alias Incident.EventStore.Ecto.{Query, Repo}

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts \\ []) do
    url = Keyword.get(opts, :url)

    Repo.start_link(url: url)
  end

  @impl true
  def get(aggregate_id) do
    aggregate_id
    |> Query.get()
    |> Repo.all()
  end

  @impl true
  def append(_event) do
    {:ok, %PersistedEvent{}}
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
