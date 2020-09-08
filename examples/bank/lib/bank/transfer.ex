defmodule Bank.Transfer do
  @behaviour Incident.Aggregate

  alias Bank.TransferState
  alias Bank.Commands.{InitiateTransfer}
  alias Bank.Events.{TransferInitiated}

  @impl true
  def execute(%InitiateTransfer{aggregate_id: aggregate_id} = command) do
    case TransferState.get(aggregate_id) do
      %{aggregate_id: nil} = state ->
        new_event = %TransferInitiated{
          aggregate_id: aggregate_id,
          source_account_number: command.source_account_number,
          destination_account_number: command.destination_account_number,
          amount: command.amount,
          version: 1
        }

        {:ok, new_event, state}

      _state ->
        {:error, :transfer_already_initiated}
    end
  end

  @impl true
  def apply(%{event_type: "TransferInitiated"} = event, state) do
    %{
      state
      | aggregate_id: event.aggregate_id,
        source_account_number: event.event_data["source_account_number"],
        destination_account_number: event.event_data["destination_account_number"],
        amount: event.event_data["amount"],
        status: :initiated,
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(_, state) do
    state
  end
end
