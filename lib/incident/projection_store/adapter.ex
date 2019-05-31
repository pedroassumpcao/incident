defmodule Incident.ProjectionStore.Adapter do
  @moduledoc """
  Defines the API for a Projection Store adapter.
  """

  @doc """
  Insert or updates a projection in the Projection Store.

  Receives the projection type and the data for the projection.
  """
  @callback project(:atom, map) :: :ok

  @doc """
  Returns all projections from a specific projection type from the Projection Store.
  """
  @callback all(:atom) :: list
end
