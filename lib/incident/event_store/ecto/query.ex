defmodule Incident.EventStore.Ecto.Query do
  import Ecto.Query, only: [from: 2]

  def get(aggregate_id) do
    from(
      e in "events",
      where: e.aggregate_id == ^aggregate_id,
      order_by: [asc: e.event_date]
    )
  end
end
