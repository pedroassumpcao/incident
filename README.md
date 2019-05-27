# Incident

Event Sourcing and CQRS in Elixir made simple.

## Goals

* incentivize the usage of *Event Sourcing* and *CQRS* as good choice for domains that can leverage the main benefits of this design pattern;
* serve as guidance when using Event Sourcing in your system;
* leverage functions and reducers for executing commands and applying events;
* allow customization for fine-grained needs without compromising the principles;

## Event Sourcing and CQRS

In a nutshell, Event Sourcing ensures that all changes to application state are stored as a sequence of events. But if you are new to *Event Sourcing* and *CQRS* I highly recommend watch [Greg Young's presentation at Code on the Beach 2014](https://www.youtube.com/watch?v=JHGkaShoyNs) before moving forward.

## Main Components

* *Command* is a data structure with basic validation;
* *Event* is a data structure;
* *Aggregate* only defines its business logic to execute a command and apply an event, but not its state;
* *Aggregate State* is defined by playing all the events through Aggregate business logic;
* *Event Store* and *Projection Store* are swappable persistence layers to allow different technologies over time;
* *Projection* can be rebuilt based on the persisted events and on the same Aggregate business logic;

## Roadmap

### Next Steps
- [ ] use `Ecto.Schema` for command and event data structure;
- [ ] publish version `0.1.0` to Hex and make repository public;
- [ ] create a new repo `incident_example` with a project implementing `incident` as a reference for newcomers;
- [ ] add Postgres as an option for event and projection storage via a built-in Ecto Adapter;

### Steps Done
- [x] create a *Proof of Concept* that can exercise all library components, implementation and confirm goals;
- [x] extract library components from the POC, remove implementation and document the implementation in the `README`;

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `incident` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:incident, "~> 0.1.0"}
  ]
end
```

## Getting Started

As an implementation example, a *Bank Account* application that allow two commands, to *open an account* and to *deposit money into an account*. If the commands can be executed, based on the aggregate business logic, the events are stored and broadcasted to an event handler that will project them.

### Implementation

### Event Store and Projection Store Setup

Simply add both children specs in the application supervision tree. This will setup the In Memory Adapter for both stores:

```elixir
{Incident.EventStore.InMemoryAdapter, []},
{Incident.ProjectionStore.InMemoryAdapter, %{bank_accounts: []}}
```

#### Commands

Define the commands as structs:

```elixir
defmodule Bank.Command.OpenAccount do
  defstruct [:account_number]
end

defmodule Bank.Command.DepositMoney do
  defstruct [:aggregate_id, :amount]
end
```

#### Events

Define the events as structs:

```elixir
defmodule Bank.Event.AccountOpened do
  defstruct [:aggregate_id, :account_number, :version]
end

defmodule Bank.Event.MoneyDeposited do
  defstruct [:aggregate_id, :amount, :version]
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
```

#### Aggregate State

The *Aggregate State* is used to accumulate the state of an aggregate after every event applied. It starts the initial state of an aggregate.

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

The *Event Handler* will define the business logic for every event. The most common, it is to project new data to the *Projection Store*.

```elixir
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
```

#### Projection

Define the projection as structs:

```elixir
defmodule Bank.Projection.BankAccount do
  defstruct [:aggregate_id, :account_number, :version, :balance, :event_id, :event_date]
end
```

### Usage in IEx

```elixir
# Create a command to open an account
iex 1 > command_open = %Bank.Command.OpenAccount{account_number: "abc"}
%Bank.Command.OpenAccount{account_number: "abc"}

# Create a command to deposit money for an aggregate
iex 2 > command_deposit = %Bank.Command.DepositMoney{aggregate_id: "abc", amount: 100}
%Bank.Command.DepositMoney{aggregate_id: "abc", amount: 100}

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
  %Incident.Projection.BankAccount{
    account_number: "abc",
    aggregate_id: "abc",
    balance: 200,
    event_date: #DateTime<2019-05-20 21:19:01.726610Z>,
    event_id: "39233",
    version: 3
  }
]
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/incident](https://hexdocs.pm/incident).

