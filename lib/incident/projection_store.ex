defmodule Incident.ProjectionStore do
  @moduledoc """
  Defines the API to interact with the Projection Store.

  The data source is based on the configured Projection Store Adapter.
  """

  use GenServer

  def start_link([adapter: _adapter, options: _options] = config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(adapter: adapter, options: options) do
    adapter.start_link(options)
    {:ok, %{adapter: adapter}}
  end

  @doc false
  def project(projection_name, data) do
    GenServer.call(__MODULE__, {:project, projection_name, data})
  end

  @doc false
  def all(projection_name) do
    GenServer.call(__MODULE__, {:all, projection_name})
  end

  @doc false
  def get(projection_name, aggregate_id) do
    GenServer.call(__MODULE__, {:get, projection_name, aggregate_id})
  end

  @impl true
  def handle_call({:project, projection_name, data}, _from, %{adapter: adapter} = state) do
    reply = adapter.project(projection_name, data)
    {:reply, reply, state}
  end

  def handle_call({:all, projection_name}, _from, %{adapter: adapter} = state) do
    projections = adapter.all(projection_name)
    {:reply, projections, state}
  end

  def handle_call({:get, projection_name, aggregate_id}, _from, %{adapter: adapter} = state) do
    projection = adapter.get(projection_name, aggregate_id)
    {:reply, projection, state}
  end
end
