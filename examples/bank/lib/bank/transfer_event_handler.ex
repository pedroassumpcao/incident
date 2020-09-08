defmodule Bank.TransferEventHandler do
  @behaviour Incident.EventHandler

  alias Bank.Projections.Transfer
  alias Bank.Transfer, as: Aggregate
  alias Incident.ProjectionStore

  @impl true
  def listen(%{event_type: "TransferInitiated"} = event, state) do
    new_state = Aggregate.apply(event, state)

    data = %{
      aggregate_id: new_state.aggregate_id,
      source_account_number: new_state.source_account_number,
      destination_account_number: new_state.destination_account_number,
      status: new_state.status,
      amount: new_state.amount,
      version: event.version,
      event_id: event.event_id,
      event_date: event.event_date
    }

    ProjectionStore.project(Transfer, data)
  end
end
