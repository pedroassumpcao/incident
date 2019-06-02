defmodule Incident.EventStore do
  @moduledoc """
  Defines the API to interact with the Event Store.

  The data source is based on the configured Event Store Adapter.
  """

  @doc false
  def get(aggregate_id) do
    apply(adapter(), :get, [aggregate_id])
  end

  @doc false
  def append(event) do
    apply(adapter(), :append, [event])
  end

  @spec adapter :: module
  defp adapter do
    Application.get_env(:incident, :event_store)[:adapter]
  end
end
