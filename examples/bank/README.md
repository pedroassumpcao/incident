# Bank Application

Example application using **Incident** for Event Sourcing and CQRS.

## Getting Started

As an implementation example, a **Bank** application that allow few commands, such as to **open an
account**, to **deposit money into an account**, **transfer money from one account to another**, and so on.
If the commands can be executed, based on the aggregate logic, the events are stored and broadcasted to an
event handler that will project them.

### Implementation

The code snippets below are only part of what we currently have in this example application. There are many
more commands, events, aggregates and handlers. The integration tests in this application contains many
details of all allowed operations and it is a very good place to understand how the application impelements
Event Sourcing using Incident.

#### Setup

`Incident` is added to the application supervision tree with the adapter configuration for both **Event Store**
and **Projection Store**.

#### Postgres Adapters

The Postgres adapter uses `Ecto` behind the scenes so a lot of its configuration it is simply how you should
configure a Postgres database for any application using Ecto.

In the main `config.exs`:

```elixir
config :bank, ecto_repos: [Bank.EventStoreRepo, Bank.ProjectionStoreRepo]
```

In the application `dev.exs`:

```elixir
config :bank, Bank.EventStoreRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "bank_event_store_dev"

config :bank, Bank.ProjectionStoreRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "bank_projection_store_dev"
```

Migrations for the events table and the projections are already available but you need to run some
mix tasks for the final database setup:

```
mix ecto.create
mix ecto.migrate
```

`Incident` is defined in `application.ex`, being added into the application supervision tree:

```
defmodule Bank.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    config = %{
      event_store: %{
        adapter: :postgres,
        options: [repo: Bank.EventStoreRepo]
      },
      projection_store: %{
        adapter: :postgres,
        options: [repo: Bank.ProjectionStoreRepo]
      }
    }

    children = [
      Bank.EventStoreRepo,
      Bank.ProjectionStoreRepo,
      {Incident, config}
    ]

    opts = [strategy: :one_for_one, name: Bank.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

#### Commands

Implement the behaviour `Incident.Command`. Below are two examples that demonstrate how commands can be
implemented using basic Elixir structs or leveraging `Ecto.Schema` with embedded schemas and
`Ecto.Changeset` for validations. It is up to you decide the best approach:

```elixir
defmodule Bank.Commands.OpenAccount do
  @behaviour Incident.Command

  defstruct [:aggregate_id]

  @impl true
  def valid?(command) do
    not is_nil(command.aggregate_id)
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

defmodule Bank.Commands.WithdrawMoney do
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

Below are two examples that demonstrate how event data structures can be defined using basic Elixir structs
or leveraging `Ecto.Schema` with embedded schemas. These data will be used as the content of `event_data`
field in the persisted event data structure, but this is handle automatically by Incident:

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

defmodule Bank.Events.MoneyWithdrawn do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:aggregate_id, :string)
    field(:amount, :integer)
    field(:version, :integer)
  end
end
```

#### Command Handler

The **Command Handler** is the entry point in the command/write model. Its task is to receive, validate and
exectue the command through the aggregate. If a command is invalid in its structure and basic data, the
command handler will reject it, returning a invalid command error.

The command handler will also broadcast the event to the **Event Handler**.

```elixir
defmodule Bank.BankAccountCommandHandler do
  use Incident.CommandHandler,
    aggregate: Bank.BankAccount,
    event_handler: Bank.BankAccountEventHandler
end
```

#### Aggregate

The aggregate will implement two functions:

* `execute/1`, it will receive a command and based on the business logic and on the current aggregate
state, return a new event or an error;
* `apply/2`, it will receive an event and an aggregate state, returning the new aggregate state;

The responsibility of the aggregate is define what has to be done for each command it accepts and each
event that can happen around it. The aggregate logic is pure functional, there is no side effects.

```elixir
defmodule Bank.BankAccount do
  @behaviour Incident.Aggregate

  alias Bank.BankAccountState
  alias Bank.Commands.{DepositMoney, OpenAccount, WithdrawMoney}
  alias Bank.Events.{AccountOpened, MoneyDeposited, MoneyWithdrawn}

  @impl true
  def execute(%OpenAccount{aggregate_id: aggregate_id}) do
    case BankAccountState.get(aggregate_id) do
      %{aggregate_id: nil} = state ->
        new_event = %AccountOpened{
          aggregate_id: aggregate_id,
          account_number: aggregate_id,
          version: 1
        }

        {:ok, new_event, state}

      _state ->
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

      %{aggregate_id: nil} ->
        {:error, :account_not_found}
    end
  end

  @impl true
  def execute(%WithdrawMoney{aggregate_id: aggregate_id, amount: amount}) do
    with %{aggregate_id: aggregate_id} = state when not is_nil(aggregate_id) <-
           BankAccountState.get(aggregate_id),
         true <- state.balance >= amount do
      new_event = %MoneyWithdrawn{
        aggregate_id: aggregate_id,
        amount: amount,
        version: state.version + 1
      }

      {:ok, new_event, state}
    else
      %{aggregate_id: nil} -> {:error, :account_not_found}
      false -> {:error, :no_enough_balance}
    end
  end

  # ...
  # Other command execution implementation.
  # ...

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
  def apply(%{event_type: "MoneyWithdrawn"} = event, state) do
    %{
      state
      | balance: state.balance - event.event_data["amount"],
        version: event.version,
        updated_at: event.event_date
    }
  end

  # ...
  # Other event application implementation.
  # ...
end
```

#### Aggregate State

The **Aggregate State** is used to accumulate the state of an aggregate after every event applied.
It also defines the initial state of an aggregate.

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

The **Event Handler** will define the business logic for every event that happened. The most common it is
to project new data to the **Projection Store** but any other side effect could happen here as well, such
as compose a new command and send to the Command Handler.

```elixir
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
iex 1 > command_open = %Bank.Commands.OpenAccount{aggregate_id: "abc"}
%Bank.Commands.OpenAccount{aggregate_id: "abc"}

# Create a command to deposit money for an aggregate
iex 2 > command_deposit = %Bank.Commands.DepositMoney{aggregate_id: "abc", amount: 100}
%Bank.Commands.DepositMoney{aggregate_id: "abc", amount: 100}

# Create a command to withdraw money for an aggregate
iex 3 > command_withdraw = %Bank.Commands.WithdrawMoney{aggregate_id: "abc", amount: 125}
%Bank.Commands.WithdrawMoney{aggregate_id: "abc", amount: 25}

# Successful commands being executed
iex 4 > Bank.BankAccountCommandHandler.receive(command_open)
{:ok,
 %Incident.EventStore.PostgresEvent{
   __meta__: #Ecto.Schema.Metadata<:loaded, "events">,
   aggregate_id: "abc",
   event_data: %{"aggregate_id" => "abc", "account_number" => "abc", "version" => 1},
   event_date: #DateTime<2020-10-24 22:06:48.238223Z>,
   event_id: "431eb402-f476-44ec-a868-7742d04b5e95",
   event_type: "AccountCreated",
   id: 1,
   inserted_at: #DateTime<2020-10-24 22:06:48.847365Z>,
   updated_at: #DateTime<2020-10-24 22:06:48.847365Z>,
   version: 1
 }}
iex 5 > Bank.BankAccountCommandHandler.receive(command_deposit)
{:ok,
 %Incident.EventStore.PostgresEvent{
   __meta__: #Ecto.Schema.Metadata<:loaded, "events">,
   aggregate_id: "abc",
   event_data: %{"aggregate_id" => "abc", "amount" => 100, "version" => 2},
   event_date: #DateTime<2020-10-24 22:06:49.487129Z>,
   event_id: "431eb402-f476-44ec-a868-7742d04b5e95",
   event_type: "MoneyDeposited",
   id: 2,
   inserted_at: #DateTime<2020-10-24 22:06:49.491902Z>,
   updated_at: #DateTime<2020-10-24 22:06:49.491902Z>,
   version: 2
 }}
iex 6 > Bank.BankAccountCommandHandler.receive(command_deposit)
{:ok,
 %Incident.EventStore.PostgresEvent{
   __meta__: #Ecto.Schema.Metadata<:loaded, "events">,
   aggregate_id: "abc",
   event_data: %{"aggregate_id" => "abc", "amount" => 100, "version" => 3},
   event_date: #DateTime<2020-10-24 22:09:05.323817Z>,
   event_id: "81c6ff50-0f23-4046-80e3-4000ce3653d8",
   event_type: "MoneyDeposited",
   id: 3,
   inserted_at: #DateTime<2020-10-24 22:09:05.323944Z>,
   updated_at: #DateTime<2020-10-24 22:09:05.323944Z>,
   version: 3
 }}
iex 7 > Bank.BankAccountCommandHandler.receive(command_withdraw)
{:ok,
 %Incident.EventStore.PostgresEvent{
   __meta__: #Ecto.Schema.Metadata<:loaded, "events">,
   aggregate_id: "abc",
   event_data: %{"aggregate_id" => "abc", "amount" => 125, "version" => 4},
   event_date: #DateTime<2020-10-24 22:09:45.987814Z>,
   event_id: "bec52025-c7d0-4f33-84ec-76d31aee0454",
   event_type: "MoneyWithdrawn",
   id: 4,
   inserted_at: #DateTime<2020-10-24 22:09:45.987904Z>,
   updated_at: #DateTime<2020-10-24 22:09:45.987904Z>,
   version: 4
 }}

# Commands are executed in the aggregate business logic, and can generate business logic errors
iex 8 > Bank.BankAccountCommandHandler.receive(command_open)
{:error, :account_already_open}

iex 9 > Bank.BankAccountCommandHandler.receive(command_withdraw)
{:error, :no_enough_balance}

# Fetching all events for a specific aggregate
iex 10 > Incident.EventStore.get("abc")
[
  %Incident.EventStore.PostgresEvent{
    __meta__: #Ecto.Schema.Metadata<:loaded, "events">,
    aggregate_id: "abc",
    event_data: %{
      "account_number" => "abc",
      "aggregate_id" => "abc",
      "version" => 1
    },
    event_date: #DateTime<2020-10-20 20:58:13.279033Z>,
    event_id: "d6b3f6d2-d022-4de0-9b40-6cc13fbd0202",
    event_type: "AccountOpened",
    id: 1,
    inserted_at: #DateTime<2020-10-20 20:58:13.284767Z>,
    updated_at: #DateTime<2020-10-20 20:58:13.284767Z>,
    version: 1
  },
  %Incident.EventStore.PostgresEvent{
    __meta__: #Ecto.Schema.Metadata<:loaded, "events">,
    aggregate_id: "abc",
    event_data: %{"aggregate_id" => "abc", "amount" => 100, "version" => 2},
    event_date: #DateTime<2020-10-24 22:06:49.487129Z>,
    event_id: "431eb402-f476-44ec-a868-7742d04b5e95",
    event_type: "MoneyDeposited",
    id: 2,
    inserted_at: #DateTime<2020-10-24 22:06:49.491902Z>,
    updated_at: #DateTime<2020-10-24 22:06:49.491902Z>,
    version: 2
  },
  %Incident.EventStore.PostgresEvent{
    __meta__: #Ecto.Schema.Metadata<:loaded, "events">,
    aggregate_id: "abc",
    event_data: %{"aggregate_id" => "abc", "amount" => 100, "version" => 3},
    event_date: #DateTime<2020-10-24 22:09:05.323817Z>,
    event_id: "81c6ff50-0f23-4046-80e3-4000ce3653d8",
    event_type: "MoneyDeposited",
    id: 3,
    inserted_at: #DateTime<2020-10-24 22:09:05.323944Z>,
    updated_at: #DateTime<2020-10-24 22:09:05.323944Z>,
    version: 3
  },
  %Incident.EventStore.PostgresEvent{
    __meta__: #Ecto.Schema.Metadata<:loaded, "events">,
    aggregate_id: "abc",
    event_data: %{"aggregate_id" => "abc", "amount" => 125, "version" => 4},
    event_date: #DateTime<2020-10-24 22:09:45.987814Z>,
    event_id: "bec52025-c7d0-4f33-84ec-76d31aee0454",
    event_type: "MoneyWithdrawn",
    id: 4,
    inserted_at: #DateTime<2020-10-24 22:09:45.987904Z>,
    updated_at: #DateTime<2020-10-24 22:09:45.987904Z>,
    version: 4
  }
]

# Listing all bank accounts from the Projection Store
iex 11 > Incident.ProjectionStore.all(Bank.Projections.BankAccount)
[
  %Bank.Projections.BankAccount{
    __meta__: #Ecto.Schema.Metadata<:loaded, "bank_accounts">,
    account_number: "abc",
    aggregate_id: "abc",
    balance: 75,
    event_date: #DateTime<2020-10-24 22:09:45.987814Z>,
    event_id: "bec52025-c7d0-4f33-84ec-76d31aee0454",
    id: 1,
    inserted_at: #DateTime<2020-10-20 20:58:13.311756Z>,
    updated_at: #DateTime<2020-10-24 22:09:45.996697Z>,
    version: 4
  }
]

# Fetching a specific bank account from the Projection Store based on its aggregate id
iex 12 > Incident.ProjectionStore.get(Bank.Projections.BankAccount, "abc")
%Bank.Projections.BankAccount{
  __meta__: #Ecto.Schema.Metadata<:loaded, "bank_accounts">,
  account_number: "abc",
  aggregate_id: "abc",
  balance: 75,
  event_date: #DateTime<2020-10-24 22:09:45.987814Z>,
  event_id: "bec52025-c7d0-4f33-84ec-76d31aee0454",
  id: 1,
  inserted_at: #DateTime<2020-10-20 20:58:13.311756Z>,
  updated_at: #DateTime<2020-10-24 22:09:45.996697Z>,
  version: 4
}
```
