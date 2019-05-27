defmodule Incident.EventStore do
  def get(aggregate_id) do
    apply(adapter(), :get, [aggregate_id])
  end

  def append(event) do
    apply(adapter(), :append, [event])
  end

  defp adapter do
    Incident.EventStore.InMemoryAdapter
  end
end
