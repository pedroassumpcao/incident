defmodule Incident.EventHandler do
  @moduledoc """
  Defines the API for an Event Handler.
  """

  alias Incident.Event.PersistedEvent

  @doc """
  Listens to a persisted event and an aggregate state.
  You can use the aggregate to update its new state and projects new data
  into the projection store.
  """
  @callback listen(PersistedEvent.t(), map) :: :ok
end
