defmodule Incident.EventStore do
  @moduledoc """
  Defines the API to interact with the Event Store.

  The data source is based on the configured Event Store Adapter.
  """

  use GenServer

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(%{adapter: adapter, options: options} = config) do
    :persistent_term.put(__MODULE__, config)
    adapter.start_link(options)
    {:ok, config}
  end

  @doc false
  def append(event) do
    GenServer.call(__MODULE__, {:append, event})
  end

  @doc false
  def get(aggregate_id) do
    %{adapter: adapter} = :persistent_term.get(__MODULE__)
    adapter.get(aggregate_id)
  end

  @doc false
  def acquire_lock(aggregate_id, owner) do
    lock_manager().acquire_lock(aggregate_id, owner)
  end

  @doc false
  def release_lock(aggregate_id, owner) do
    lock_manager().release_lock(aggregate_id, owner)
  end

  @impl true
  def handle_call({:append, event}, _from, %{adapter: adapter} = state) do
    reply = adapter.append(event)
    {:reply, reply, state}
  end

  @spec lock_manager :: Incident.EventStoreSupervisor.lock_manager()
  defp lock_manager do
    %{options: options} = :persistent_term.get(__MODULE__)
    Keyword.fetch!(options, :lock_manager)
  end
end
