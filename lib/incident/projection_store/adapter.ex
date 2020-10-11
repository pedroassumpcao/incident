defmodule Incident.ProjectionStore.Adapter do
  @moduledoc """
  Defines the API for a Projection Store adapter.
  """

  @doc """
  Insert or updates a projection in the Projection Store.

  Receives the projection type and the data for the projection.
  """
  @callback project(module, map) :: {:ok | :error, map}

  @doc """
  Returns all projections from a specific projection type from the Projection Store.
  """
  @callback all(module) :: list

  @doc """
  Returns a projection record from a specific projection type from the Projection Store.
  """
  @callback get(module, String.t()) :: struct | nil
end
