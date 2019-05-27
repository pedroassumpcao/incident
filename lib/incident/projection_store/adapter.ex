defmodule Incident.ProjectionStore.Adapter do
  @callback project(:atom, map) :: map
  @callback all(:atom) :: list
end
