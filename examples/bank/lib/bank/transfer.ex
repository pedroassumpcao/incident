defmodule Bank.Transfer do
  @behaviour Incident.Aggregate

  alias Bank.TransferState
  alias Bank.Commands.{CancelTransfer, CompleteTransfer, RequestTransfer}
  alias Bank.Events.{TransferCancelled, TransferCompleted, TransferRequested}

  @impl true
  def execute(%RequestTransfer{aggregate_id: aggregate_id} = command) do
    case TransferState.get(aggregate_id) do
      %{aggregate_id: nil} = state ->
        new_event = %TransferRequested{
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
  def execute(%CompleteTransfer{aggregate_id: aggregate_id}) do
    case TransferState.get(aggregate_id) do
      %{aggregate_id: aggregate_id, status: "requested"} = state when not is_nil(aggregate_id) ->
        new_event = %TransferCompleted{aggregate_id: aggregate_id, version: state.version + 1}
        {:ok, new_event, state}

      %{aggregate_id: nil} ->
        {:error, :transfer_not_found}

      _ ->
        {:error, :transfer_invalid_status}
    end
  end

  @impl true
  def execute(%CancelTransfer{aggregate_id: aggregate_id}) do
    case TransferState.get(aggregate_id) do
      %{aggregate_id: aggregate_id, status: "requested"} = state when not is_nil(aggregate_id) ->
        new_event = %TransferCancelled{aggregate_id: aggregate_id, version: state.version + 1}
        {:ok, new_event, state}

      %{aggregate_id: nil} ->
        {:error, :transfer_not_found}

      _ ->
        {:error, :transfer_invalid_status}
    end
  end

  @impl true
  def apply(%{event_type: "TransferRequested"} = event, state) do
    %{
      state
      | aggregate_id: event.aggregate_id,
        source_account_number: event.event_data["source_account_number"],
        destination_account_number: event.event_data["destination_account_number"],
        amount: event.event_data["amount"],
        status: "requested",
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(%{event_type: "TransferCompleted"} = event, state) do
    %{
      state
      | aggregate_id: event.aggregate_id,
        status: "completed",
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(%{event_type: "TransferCancelled"} = event, state) do
    %{
      state
      | aggregate_id: event.aggregate_id,
        status: "cancelled",
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(_, state) do
    state
  end
end
