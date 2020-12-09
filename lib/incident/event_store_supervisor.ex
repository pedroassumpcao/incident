defmodule Incident.EventStoreSupervisor do
  @moduledoc false

  use Supervisor

  alias Incident.EventStore
  alias Incident.EventStore.{InMemory, Postgres}

  @type adapter :: InMemory.Adapter | Postgres.Adapter
  @type lock_manager :: InMemory.LockManager | Postgres.LockManager

  @doc """
  Starts the Event Store Supervisor that monitors the Event Store and Lock Manager.
  """
  @spec start_link(map()) :: Supervisor.on_start()
  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(%{adapter: adapter, options: options} = config) do
    lock_manager = [lock_manager: lock_manager_for(adapter)]
    event_store_config = Map.update(config, :options, lock_manager, &(&1 ++ lock_manager))

    lock_manager_config = Keyword.get(options, :lock_manager_config, [])

    children = [
      {lock_manager_for(adapter), lock_manager_config},
      {EventStore, event_store_config}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec lock_manager_for(adapter()) :: lock_manager()
  defp lock_manager_for(Postgres.Adapter), do: Postgres.LockManager

  defp lock_manager_for(InMemory.Adapter), do: InMemory.LockManager
end
