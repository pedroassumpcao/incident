# Bank

Example application using **Incident** for Event Sourcing and CQRS.

## Getting Started

As an implementation example, a **Bank** application that allow few commands, to **open an account** and to **deposit money into an account**.
If the commands can be executed, based on the aggregate business logic, the events are stored and broadcasted to an event handler that will project them.

### Implementation

The implementation below is what we have currently in this example application:

### Event Store and Projection Store Setup

Configure `incident` **Event Store** and **Projection Store** adapters and its options. The options will be used during the adapter initialization.

There are two options for persistency and the adapter configuration follows below:

#### In Memory Adapter

This is simply a quick option to be used as a playground to exercise the library but it is not
suppose to be used in a real application as the data will be wiped out every time the application starts.

The Event Store will start as an empty list (no events), and the Projection Store will have an empty list of bank accounts as the only projection:

```elixir
config :incident, :event_store, adapter: Incident.EventStore.InMemoryAdapter,
  options: [
    initial_state: []
]

config :incident, :projection_store, adapter: Incident.ProjectionStore.InMemoryAdapter,
  options: [
    initial_state: %{Bank.Projections.BankAccount => []}
]
```

#### Postgres Adapter

In the case of using the Postgres Adapter, that uses `Ecto` behind the scenes, we need some extra
configuration that is identical to any configuration for `Ecto`. This example app is already
configured with this adapter with the following setup:

In `config.exs` the repositories are specified:

```elixir
config :bank, ecto_repos: [Bank.EventStoreRepo, Bank.ProjectionStoreRepo]
```

In the application `dev.exs`:

```elixir
config :bank, Bank.EventStoreRepo, url: "ecto://postgres:postgres@localhost/bank_event_store_dev"

config :bank, Bank.ProjectionStoreRepo, url: "ecto://postgres:postgres@localhost/bank_projection_store_dev"

config :incident, :event_store, adapter: Incident.EventStore.PostgresAdapter,
  options: [
    repo: Bank.EventStoreRepo
  ]

config :incident, :projection_store, adapter: Incident.ProjectionStore.PostgresAdapter,
  options: [
    repo: Bank.ProjectionStoreRepo
  ]
```

Migrations for the events table and the projections are already available but you need to run some
mix tasks for the final database setup:

```
mix ecto.create
mix ecto.migrate
```

#### Commands

Implement the behaviour `Incident.Command`. Below are two examples that demonstrate how commands can be implemented using basic Elixir structs or leveraging `Ecto.Schema` with embedded schemas and `Ecto.Changeset` for validations:

```elixir
defmodule Bank.Commands.OpenAccount do
  @behaviour Incident.Command

  defstruct [:account_number]

  @impl true
  def valid?(command) do
    not is_nil(command.account_number)
  end
end

defmodule Bank.Commands.DepositMoney do
  @behaviour Incident.Command

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:aggregate_id, :string)
    field(:amount, :integer)
  end

  @required_fields ~w(aggregate_id amount)a

  @impl true
  def valid?(command) do
    data = Map.from_struct(command)

    %__MODULE__{}
    |> cast(data, @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:amount, greater_than: 0)
    |> Map.get(:valid?)
  end
end
```

#### Events

Below are two examples that demonstrate how event data structures can be defined using basic Elixir structs or leveraging `Ecto.Schema` with embedded schemas. For information only, these data will be used as the `event_data` in the event data structure, but this is handle automatically by Incident:

```elixir
defmodule Bank.Events.AccountOpened do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:aggregate_id, :string)
    field(:account_number, :string)
    field(:version, :integer)
  end
end

defmodule Bank.Events.MoneyDeposited do
  defstruct [:aggregate_id, :amount, :version]
end
```

#### Command Handler

The **Command Handler** is the entry point in the command model. Its task is receive, validate and exectue the command through the aggregate. If a command is invalid in its structure and basic data, the command handler will reject it, returning a invalid command error.

```elixir
defmodule Bank.BankAccountCommandHandler do
  use Incident.CommandHandler, aggregate: Bank.BankAccount
end
```

#### Aggregate

The aggregate will implement two functions:

* `execute/1`, it will receive a command and based on the business logic and on the current aggregate state, return a new event or an error;
* `apply/2`, it will receive an event and an aggregate state, returning the new aggregate state;

The aggregate logic is pure functional, there is no side effects.

```elixir
defmodule Bank.BankAccount do
  @behaviour Incident.Aggregate

  alias Bank.BankAccountState
  alias Bank.Commands.{DepositMoney, OpenAccount}
  alias Bank.Events.{AccountOpened, MoneyDeposited}

  @impl true
  def execute(%OpenAccount{account_number: account_number}) do
    case BankAccountState.get(account_number) do
      %{account_number: nil} = state ->
        new_event = %AccountOpened{
          aggregate_id: account_number,
          account_number: account_number,
          version: 1
        }

        {:ok, new_event, state}

      _ ->
        {:error, :account_already_opened}
    end
  end

  @impl true
  def execute(%DepositMoney{aggregate_id: aggregate_id, amount: amount}) do
    case BankAccountState.get(aggregate_id) do
      %{aggregate_id: aggregate_id} = state when not is_nil(aggregate_id) ->
        new_event = %MoneyDeposited{
          aggregate_id: aggregate_id,
          amount: amount,
          version: state.version + 1
        }

        {:ok, new_event, state}

      _ ->
        {:error, :account_not_found}
    end
  end

  @impl true
  def apply(%{event_type: "AccountOpened"} = event, state) do
    %{
      state
      | aggregate_id: event.aggregate_id,
        account_number: event.event_data["account_number"],
        balance: 0,
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(%{event_type: "MoneyDeposited"} = event, state) do
    %{
      state
      | balance: state.balance + event.event_data["amount"],
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

The **Event Handler** will define the business logic for every event that happened. The most common it is to project new data to the **Projection Store** but any other side effect could happen here as well.

```elixir
defmodule Bank.EventHandler do
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
      account_number: new_state.account_number,
      balance: new_state.balance,
      version: event.version,
      event_id: event.event_id,
      event_date: event.event_date
    }

    ProjectionStore.project(BankAccount, data)
  end
end
```

#### Projection

The projection uses `Ecto.Schema` and `Ecto.Changeset`. All projections, besides all desired fields
to fulfill the application domain will require the fields `version`, `event_id` and `event_date`:

```elixir
defmodule Bank.Projections.BankAccount do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bank_accounts" do
    field(:aggregate_id, :string)
    field(:account_number, :string)
    field(:balance, :integer)
    field(:version, :integer)
    field(:event_id, :binary_id)
    field(:event_date, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end

  @required_fields ~w(aggregate_id account_number balance version event_id event_date)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
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
iex 3 > Bank.BankAccountCommandHandler.receive(command_open)
:ok
iex 4 > Bank.BankAccountCommandHandler.receive(command_deposit)
:ok
iex 5 > Bank.BankAccountCommandHandler.receive(command_deposit)
:ok

# Commands are executed in the aggregate business logic, and can generate business logic errors
iex 6 > Bank.BankAccountCommandHandler.receive(command_open)
{:error, :account_already_open}

# Fetching all events for a specific aggregate
iex 7 > Incident.EventStore.get("abc")
[
  %Incident.EventStore.PostgresEvent{
    aggregate_id: "abc",
    event_data: %{account_number: "abc", aggregate_id: "abc", version: 1},
    event_date: #DateTime<2019-05-20 21:18:32.892658Z>,
    event_id: "94618",
    event_type: "AccountOpened",
    version: 1
  },
  %Incident.EventStore.PostgresEvent{
    aggregate_id: "abc",
    event_data: %{aggregate_id: "abc", amount: 100, version: 2},
    event_date: #DateTime<2019-05-20 21:18:46.171031Z>,
    event_id: "82370",
    event_type: "MoneyDeposited",
    version: 2
  },
  %Incident.EventStore.PostgresEvent{
    aggregate_id: "abc",
    event_data: %{aggregate_id: "abc", amount: 100, version: 3},
    event_date: #DateTime<2019-05-20 21:19:01.726610Z>,
    event_id: "39233",
    event_type: "MoneyDeposited",
    version: 3
  }
]

# Reading from the Projection Store
iex 8 > Incident.ProjectionStore.all(Bank.Projections.BankAccount)
[
  %Bank.Projections.BankAccount{
    account_number: "abc",
    aggregate_id: "abc",
    balance: 200,
    event_date: #DateTime<2019-05-20 21:19:01.726610Z>,
    event_id: "39233",
    version: 3
  }
]
```
