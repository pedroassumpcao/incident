defmodule Incident.Event.PersistedEvent do
  defstruct [:event_id, :aggregate_id, :event_type, :version, :event_date, :event_data]
end
