defmodule Incident.ProjectionStore.PostgresAdapter do
  @moduledoc """
  Implements a Projection Store using Postgres through Ecto.
  """

  @behaviour Incident.ProjectionStore.Adapter

  use GenServer

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

  @impl Incident.ProjectionStore.Adapter
  def project(projection, data) do
    case repo().get_by(projection, aggregate_id: data.aggregate_id) do
      nil ->
        projection
        |> repo().load(%{})
        |> Ecto.put_meta(state: :built)

      record -> record
    end
    |> projection.changeset(data)
    |> repo().insert_or_update()
  end

  @impl Incident.ProjectionStore.Adapter
  def all(projection) do
    repo().all(projection)
  end

  @spec repo :: module()
  defp repo do
    GenServer.call(__MODULE__, :repo)
  end

  # Update readme with:
  # - PG projection config;
  # - projection migration;
end
