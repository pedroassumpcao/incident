defmodule Incident.EventStoreSupervisor do
  @moduledoc false

  use Supervisor

  alias Incident.EventStore
  alias Incident.EventStore.{InMemory, Postgres}

  @type lock_manager :: InMemory.LockManager | Postgres.LockManager

  @doc """
  Starts the Event Store Supervisor that monitors the Event Store and Lock Manager.
  """
  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(config) do
    lock_manager_options = [lock_manager: lock_manager(config)]
    config = Keyword.update(config, :options, lock_manager_options, &(&1 ++ lock_manager_options))

    children = [
      {EventStore, config}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec lock_manager(keyword()) :: lock_manager()
  defp lock_manager(config) do
    case Keyword.get(config, :adapter) do
      Postgres.Adapter -> Postgres.LockManager
      InMemory.Adapter -> InMemory.LockManager
    end
  end
end
