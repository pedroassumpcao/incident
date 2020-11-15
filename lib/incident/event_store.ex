defmodule Incident.EventStore do
  @moduledoc """
  Defines the API to interact with the Event Store.

  The data source is based on the configured Event Store Adapter.
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
  def get(aggregate_id) do
    GenServer.call(__MODULE__, {:get, aggregate_id})
  end

  @doc false
  def append(event) do
    GenServer.call(__MODULE__, {:append, event})
  end

  @impl true
  def handle_call({:get, aggregate_id}, _from, %{adapter: adapter} = state) do
    events = adapter.get(aggregate_id)
    {:reply, events, state}
  end

  def handle_call({:append, event}, _from, %{adapter: adapter} = state) do
    reply = adapter.append(event)
    {:reply, reply, state}
  end
end
