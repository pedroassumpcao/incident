defmodule Bank.BankAccountEventHandler do
  @behaviour Incident.EventHandler

  alias Bank.Projections.BankAccount
  alias Bank.BankAccount, as: Aggregate
  alias Incident.ProjectionStore

  @impl true
  def listen(%{event_type: "AccountOpened"} = event, state) do
    new_state = Aggregate.apply(event, state)

    data = %{
      aggregate_id: new_state.aggregate_id,
      account_number: new_state.account_number,
      balance: new_state.balance,
      version: event.version,
      event_id: event.event_id,
      event_date: event.event_date
    }

    ProjectionStore.project(BankAccount, data)
  end

  @impl true
  def listen(%{event_type: "MoneyDeposited"} = event, state) do
    new_state = Aggregate.apply(event, state)

    data = %{
      aggregate_id: new_state.aggregate_id,
      balance: new_state.balance,
      version: event.version,
      event_id: event.event_id,
      event_date: event.event_date
    }

    ProjectionStore.project(BankAccount, data)
  end

  @impl true
  def listen(%{event_type: "MoneyWithdrawn"} = event, state) do
    new_state = Aggregate.apply(event, state)

    data = %{
      aggregate_id: new_state.aggregate_id,
      balance: new_state.balance,
      version: event.version,
      event_id: event.event_id,
      event_date: event.event_date
    }

    ProjectionStore.project(BankAccount, data)
  end

  @impl true
  def listen(%{event_type: "MoneySent"} = event, state) do
    new_state = Aggregate.apply(event, state)

    data = %{
      aggregate_id: new_state.aggregate_id,
      balance: new_state.balance,
      version: event.version,
      event_id: event.event_id,
      event_date: event.event_date
    }

    ProjectionStore.project(BankAccount, data)
  end
end
