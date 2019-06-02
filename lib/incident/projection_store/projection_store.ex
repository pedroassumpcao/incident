defmodule Incident.ProjectionStore do
  @moduledoc """
  Defines the API to interact with the Projection Store.

  The data source is based on the configured Projection Store Adapter.
  """

  @doc false
  def project(projection_name, data) do
    apply(adapter(), :project, [projection_name, data])
  end

  @doc false
  def all(projection_name) do
    apply(adapter(), :all, [projection_name])
  end

  @spec adapter :: module
  defp adapter do
    Application.get_env(:incident, :projection_store)[:adapter]
  end
end
