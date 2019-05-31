defmodule Incident.EventStore.Adapter do
  @moduledoc """
  Defines the API for an Event Store adapter.
  """

  @doc """
  Receives an aggregate id and returns a list containing all persisted events from the Event Store.
  """
  @callback get(String.t()) :: list

  @doc """
  Appends an event to the Event Store.
  """
  @callback append(map) :: :ok
end
