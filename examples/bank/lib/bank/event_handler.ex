defmodule Bank.EventHandler do
  alias Bank.Projections.BankAccount
  alias Bank.BankAccount, as: Aggregate
  alias Incident.Event.PersistedEvent
  alias Incident.ProjectionStore

  def listen(%PersistedEvent{event_type: "AccountOpened"} = event, state) do
    new_state = Aggregate.apply(event, state)
    data = %BankAccount{
      aggregate_id: new_state.aggregate_id,
      account_number: new_state.account_number,
      balance: new_state.balance,
      version: event.version,
      event_id: event.event_id,
      event_date: event.event_date
    }
    ProjectionStore.project(:bank_accounts, data)
  end

  def listen(%PersistedEvent{event_type: "MoneyDeposited"} = event, state) do
    new_state = Aggregate.apply(event, state)
    data = %BankAccount{
      aggregate_id: new_state.aggregate_id,
      account_number: new_state.account_number,
      balance: new_state.balance,
      version: event.version,
      event_id: event.event_id,
      event_date: event.event_date
    }
    ProjectionStore.project(:bank_accounts, data)
  end
end
