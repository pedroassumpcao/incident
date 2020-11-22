defmodule Incident.EventStoreSupervisor do
  @moduledoc false

  use Supervisor

  alias Incident.EventStore

  @doc """
  Starts the Event Store Supervisor that monitors the Event Store and Lock Manager.
  """
  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(config) do
    children = [
      {EventStore, config}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
