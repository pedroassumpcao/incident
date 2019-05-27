defmodule Incident.EventStore.Adapter do
  @callback get(String.t()) :: list
  @callback append(map) :: :ok
end
