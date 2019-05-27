defmodule Incident.ProjectionStore do
  def project(projection_name, data) do
    apply(adapter(), :project, [projection_name, data])
  end

  def all(projection_name) do
    apply(adapter(), :all, [projection_name])
  end

  defp adapter do
    Incident.ProjectionStore.InMemoryAdapter
  end
end
