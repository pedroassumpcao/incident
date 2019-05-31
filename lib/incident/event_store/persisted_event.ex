defmodule Incident.Event.PersistedEvent do
  @moduledoc """
  Defines the common data structure for any event that is persisted in the Event Store.

  All fields are required.
  """

  @enforce_keys [:event_id, :aggregate_id, :event_type, :version, :event_date, :event_data]
  defstruct [:event_id, :aggregate_id, :event_type, :version, :event_date, :event_data]
end
