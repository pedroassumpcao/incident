defmodule Bank.TransferEventHandler do
  @behaviour Incident.EventHandler

  alias Bank.{BankAccountCommandHandler, TransferCommandHandler}
  alias Bank.Commands.{CancelTransfer, CompleteTransfer, InitiateTransfer, ReceiveMoney, SendMoney}
  alias Bank.Projections.Transfer
  alias Bank.Transfer, as: Aggregate
  alias Incident.ProjectionStore

  @impl true
  def listen(%{event_type: "TransferRequested"} = event, state) do
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

    {:ok, _projected_event} = ProjectionStore.project(Transfer, data)

    %SendMoney{
      aggregate_id: new_state.source_account_number,
      transfer_id: new_state.aggregate_id,
      amount: new_state.amount
    }
    |> BankAccountCommandHandler.receive()
    |> case do
      {:ok, %{event_type: "MoneySent"}} ->
        %InitiateTransfer{aggregate_id: new_state.aggregate_id}

      _event ->
        %CancelTransfer{aggregate_id: new_state.aggregate_id}
    end
    |> TransferCommandHandler.receive()
  end

  @impl true
  def listen(%{event_type: "TransferInitiated"} = event, state) do
    new_state = Aggregate.apply(event, state)

    data = %{
      aggregate_id: new_state.aggregate_id,
      status: new_state.status,
      version: event.version,
      event_id: event.event_id,
      event_date: event.event_date
    }

    {:ok, _projected_event} = ProjectionStore.project(Transfer, data)

    %ReceiveMoney{
      aggregate_id: new_state.destination_account_number,
      transfer_id: new_state.aggregate_id,
      amount: new_state.amount
    }
    |> BankAccountCommandHandler.receive()
    |> case do
      {:ok, %{event_type: "MoneyReceived"}} ->
        %CompleteTransfer{aggregate_id: new_state.aggregate_id}

      _event ->
        %CancelTransfer{aggregate_id: new_state.aggregate_id}
    end
    |> TransferCommandHandler.receive()
  end

  @impl true
  def listen(%{event_type: "TransferCompleted"} = event, state) do
    new_state = Aggregate.apply(event, state)

    data = %{
      aggregate_id: new_state.aggregate_id,
      status: new_state.status,
      version: event.version,
      event_id: event.event_id,
      event_date: event.event_date
    }

    {:ok, _projected_event} = ProjectionStore.project(Transfer, data)
  end

  @impl true
  def listen(%{event_type: "TransferCancelled"} = event, state) do
    new_state = Aggregate.apply(event, state)

    data = %{
      aggregate_id: new_state.aggregate_id,
      status: new_state.status,
      version: event.version,
      event_id: event.event_id,
      event_date: event.event_date
    }

    {:ok, _projected_event} = ProjectionStore.project(Transfer, data)
  end
end
