# Commands
defmodule Bank.Command.OpenAccount do
  defstruct [:account_number]
end

defmodule Bank.Command.DepositMoney do
  defstruct [:aggregate_id, :amount]
end

# Events
defmodule Bank.Event.AccountOpened do
  defstruct [:aggregate_id, :account_number, :version]
end

defmodule Bank.Event.MoneyDeposited do
  defstruct [:aggregate_id, :amount, :version]
end

# Projection

defmodule Bank.Projection.BankAccount do
  defstruct [:aggregate_id, :account_number, :version, :balance, :event_id, :event_date]
end

# Event Handler
defmodule Bank.EventHandler do
  alias Bank.Projection.BankAccount
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

# Aggregate State
defmodule Bank.BankAccountState do
  use Incident.AggregateState,
    aggregate: Bank.BankAccount,
    initial_state: %{
      aggregate_id: nil,
      account_number: nil,
      balance: nil,
      version: nil,
      updated_at: nil
    }
end

# Aggregate
defmodule Bank.BankAccount do
  @behaviour Incident.Aggregate

  alias Bank.BankAccountState
  alias Bank.Command.{DepositMoney, OpenAccount}
  alias Bank.Event.{AccountOpened, MoneyDeposited}
  alias Bank.EventHandler
  alias Incident.EventStore

  @impl true
  def execute(%OpenAccount{account_number: account_number}) do
    case BankAccountState.get(account_number) do
      %{account_number: nil} = state ->
        %AccountOpened{
          aggregate_id: account_number,
          account_number: account_number,
          version: 1
        }
        |> EventStore.append()
        |> case do
          {:ok, persisted_event} -> EventHandler.listen(persisted_event, state)
          error -> error
        end

      _ ->
        {:error, :account_already_opened}
    end
  end

  @impl true
  def execute(%DepositMoney{aggregate_id: aggregate_id, amount: amount}) do
    case BankAccountState.get(aggregate_id) do
      %{aggregate_id: aggregate_id} = state when not is_nil(aggregate_id) ->
        %MoneyDeposited{
          aggregate_id: aggregate_id,
          amount: amount,
          version: state.version + 1
        }
        |> EventStore.append()
        |> case do
          {:ok, persisted_event} -> EventHandler.listen(persisted_event, state)
          error -> error
        end

      _ ->
        {:error, :account_not_found}
    end
  end

  @impl true
  def apply(%{event_type: "AccountOpened"} = event, state) do
    %{
      state
      | aggregate_id: event.aggregate_id,
        account_number: event.event_data.account_number,
        balance: 0,
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(%{event_type: "MoneyDeposited"} = event, state) do
    %{
      state
      | balance: state.balance + event.event_data.amount,
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(_, state) do
    state
  end
end
