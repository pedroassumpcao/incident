# Bank

Example application using Incident for Event Sourcing and CQRS.

## Getting Started

As an implementation example, a **Bank** application that allow two commands, to **open an account** and to **deposit money into an account**. If the commands can be executed, based on the aggregate business logic, the events are stored and broadcasted to an event handler that will project them.

### Implementation

The implementation below is what we have currently in this example application:

### Event Store and Projection Store Setup

Configure `incident` **Event Store** and **Projection Store** adapters and its options. The options will be used during the adapter initialization.

In our case, the Event Store will start as an empty list, and the Projection Store will have an empty list of `bank_accounts` as projection:

```elixir
config :incident, :event_store, adapter: Incident.EventStore.InMemoryAdapter,
  options: [
    initial_state: []
]

config :incident, :projection_store, adapter: Incident.ProjectionStore.InMemoryAdapter,
  options: [
    initial_state: %{bank_accounts: []}
]
```

#### Commands

Define the commands as structs:

```elixir
defmodule Bank.Commands.OpenAccount do
  defstruct [:account_number]
end

defmodule Bank.Commands.DepositMoney do
  defstruct [:aggregate_id, :amount]
end
```

#### Events

Define the events as structs:

```elixir
defmodule Bank.Events.AccountOpened do
  defstruct [:aggregate_id, :account_number, :version]
end

defmodule Bank.Events.MoneyDeposited do
  defstruct [:aggregate_id, :amount, :version]
end
```

#### Command Handler

The **Command Handler** is the entry point in the command model. Its task is receive, validate and exectue the command through the aggregate. If a command is invalid in its structure and basic data, the command handler will reject it, return a command error.

```elixir
defmodule Bank.BankAccountCommandHandler do
  use Incident.CommandHandler, aggregate: Bank.BankAccount
end
```

#### Aggregate

The aggregate will implement two functions:

* `execute/1`, it will receive a command and based on the business logic, append an event or return an error;
* `apply/2`, it will receive an event and an aggregate state, returning the new aggregate state;

```elixir
defmodule Bank.BankAccount do
  @behaviour Incident.Aggregate

  alias Bank.BankAccountState
  alias Bank.Commands.{DepositMoney, OpenAccount}
  alias Bank.Events.{AccountOpened, MoneyDeposited}
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
```

#### Aggregate State

The **Aggregate State** is used to accumulate the state of an aggregate after every event applied. It starts the initial state of an aggregate.

```elixir
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
```

#### Event Handler

The **Event Handler** will define the business logic for every event. The most common, it is to project new data to the **Projection Store**.

```elixir
defmodule Bank.EventHandler do
  @behaviour Incident.EventHandler

  alias Incident.Event.PersistedEvent
  alias Incident.ProjectionStore
  alias Bank.Projections.BankAccount
  alias Bank.BankAccount, as: Aggregate

  @impl true
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

  @impl true
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
```

#### Projection

Define the projection as structs:

```elixir
defmodule Bank.Projections.BankAccount do
  defstruct [:aggregate_id, :account_number, :version, :balance, :event_id, :event_date]
end
```

### Usage in IEx

```elixir
# Create a command to open an account
iex 1 > command_open = %Bank.Commands.OpenAccount{account_number: "abc"}
%Bank.Commands.OpenAccount{account_number: "abc"}

# Create a command to deposit money for an aggregate
iex 2 > command_deposit = %Bank.Commands.DepositMoney{aggregate_id: "abc", amount: 100}
%Bank.Commands.DepositMoney{aggregate_id: "abc", amount: 100}

# Successful commands being executed
iex 3 > Bank.BankAccount.execute(command_open)
:ok
iex 4 > Bank.BankAccount.execute(command_deposit)
:ok
iex 5 > Bank.BankAccount.execute(command_deposit)
:ok

# Commands are executed in the aggregate business logic, and can generate errors
iex 6 > Bank.BankAccount.execute(command_open)
{:error, :account_already_open}

# Fetching all events for a specific aggregate
iex 7 > Incident.EventStore.get("abc")
[
  %Incident.Event.PersistedEvent{
    aggregate_id: "abc",
    event_data: %{account_number: "abc", aggregate_id: "abc", version: 1},
    event_date: #DateTime<2019-05-20 21:18:32.892658Z>,
    event_id: "94618",
    event_type: "AccountOpened",
    version: 1
  },
  %Incident.Event.PersistedEvent{
    aggregate_id: "abc",
    event_data: %{aggregate_id: "abc", amount: 100, version: 2},
    event_date: #DateTime<2019-05-20 21:18:46.171031Z>,
    event_id: "82370",
    event_type: "MoneyDeposited",
    version: 2
  },
  %Incident.Event.PersistedEvent{
    aggregate_id: "abc",
    event_data: %{aggregate_id: "abc", amount: 100, version: 3},
    event_date: #DateTime<2019-05-20 21:19:01.726610Z>,
    event_id: "39233",
    event_type: "MoneyDeposited",
    version: 3
  }
]

# Reading from the Projection Store
iex 8 > Incident.ProjectionStore.all(:bank_accounts)
[
  %Incident.Projections.BankAccount{
    account_number: "abc",
    aggregate_id: "abc",
    balance: 200,
    event_date: #DateTime<2019-05-20 21:19:01.726610Z>,
    event_id: "39233",
    version: 3
  }
]
```
