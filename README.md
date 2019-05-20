# Incident

Event Sourcing and CQRS in Elixir made simple.

## Main goals

* incentivize the usage of *Event Sourcing* and *CQRS* as good choice for domains that can leverage the main benefits of this design pattern;
* offer a set of abstractions that can hold main Event Sourcing principles and components, making adoption easier;
* allow customization for fine-grained needs without compromising principles;
* take advantage of functional programming when applying one or more events into an aggregate or to project an event to a projection;

## Pillars

Besides the basic Event Sourcing principles, *Incident* stands based on some foundation pillars:

* *Command* is a simple data structure with some basic validation;
* *Event* is a simple data structure;
* *Aggregate* only defines its business logic to execute a command and apply an event, but not its state;
* *Aggregate State* is defined by playing all the events through Aggregate business logic;
* *Event Store* and *Projection Store* are swappable to allow different technologies over time;
* *Projection* can be easily rebuilt based on the persisted events and the same Aggregate business logic;

## Proof of Concept

To make sure the ideas are aligned with the goals and pillars, and before any major effort, a *Proof of Concept* was created to exercise some concepts.

The POC domain is a *bank account* that allow two commands, to *open an account* and to *deposit money into an account*. If the commands can be executd, based on the aggregate business logic, the events are stored and broadcasted to an event handler that will project them. Follow some *IEx* examples to demonstrate how the pieces tie together:

```elixir
# Create a command to open an account
iex 1 > command_open = %Incident.Command.OpenAccount{account_number: "abc"}
%Incident.Command.OpenAccount{account_number: "abc"}

# Create a command to deposit money for an aggregate
iex 2 > command_deposit = %Incident.Command.DepositMoney{aggregate_id: "abc", amount: 100}
%Incident.Command.DepositMoney{aggregate_id: "abc", amount: 100}

# Execute a command that can be done based on the aggregate state
iex 3 > Incident.BankAccount.execute(command_deposit)
{:error, :account_not_found}

# Successful commands being executed
iex 4 > Incident.BankAccount.execute(command_open)
:ok
iex 5 > Incident.BankAccount.execute(command_deposit)
:ok
iex 6 > Incident.BankAccount.execute(command_deposit)
:ok

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

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/incident](https://hexdocs.pm/incident).

