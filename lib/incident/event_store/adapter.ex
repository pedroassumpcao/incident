defmodule Incident.EventStore.Adapter do
  @moduledoc """
  Defines the API for an Event Store adapter.
  """

  alias Incident.EventStore.{InMemory, Postgres}

  @typedoc """
  Depending the adapter used to store the events, the persisted event
  will be defined by a different schema.
  """
  @type persisted_event :: InMemory.Event.t() | Postgres.Event.t()

  @doc """
  Receives an aggregate id and returns a list containing all persisted events from the Event Store.
  """
  @callback get(String.t()) :: [persisted_event]

  @doc """
  Appends an event to the Event Store.
  """
  @callback append(map) :: {:ok, persisted_event} | {:error, String.t() | struct}
end
