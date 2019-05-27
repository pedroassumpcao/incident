defmodule Incident.Aggregate do
  @callback execute(struct) :: :ok | {:error, atom}
  @callback apply(struct, map) :: map
end
