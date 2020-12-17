# Incident

Event Sourcing and CQRS building blocks.

Special thanks to my friend [Paulo Gonzalez](https://github.com/pdgonzalez872) for the name suggestion
for this library.

*This library is in constant development phase and evaluation, that means core changes still can be made.*
*While I am already using Incident in production, please be advised about the risks, once the library
reaches its maturity, a release 1.x.x will be created.*

## Goals

* incentivize the usage of **Event Sourcing** and **CQRS** as good choice for domains that can leverage
the main benefits of this design pattern;
* offer the essential building blocks for using Event Sourcing in your system with proper contracts, but
allowing specific needs to leverage what Elixir already brings to the table, for example, concurrency;
* leverage functions and reducers for executing commands and applying events, facilitating stateless tests;
* allow customization for fine-grained needs without compromising the principles;

## Getting Started

### Example Application

There is an [example application](https://github.com/pedroassumpcao/incident/tree/master/examples/bank)
that implements a **Bank** application for reference with great documentation and including all the
details and usage in **IEx** as well.

It also contains projections specific to the application domain with migration and schemas defined.

This example application will give you all the details in how to use **Incident**, including integration
tests for both `InMemory` and `Postgres` adapters for both Event Store and Projection Store.

### Blog Posts

* [Using Event Sourcing and CQRS with Incident - Part 1](https://pedroassumpcao.ghost.io/event-sourcing-and-cqrs-using-incident-part-1/)

## Event Sourcing and CQRS

In a nutshell, Event Sourcing ensures that all changes to application state are stored as a sequence of
events. But if you are new to **Event Sourcing** and **CQRS** I highly recommend watch [Greg Young's
presentation at Code on the Beach 2014](https://www.youtube.com/watch?v=JHGkaShoyNs) before moving forward.

## Main Components

### Command

It is a data structure used to define the command attributes with some basic validation.

### Command Handler

It is the entry point of a command in the **write side**. It performs basic command validation and
executes the command through the **Aggregate** logic.

### Aggregate

Defines how a specific entity (_User_, for example) in your domain will execute each of its commands and
apply each of its events. The aggregate itself only defines the logic but not its state.

### Aggregate State

Defines the initial state of an **Aggregate** and it is able to calculate the new state by replaying all
the events through the aggregate logic.

### Event

It is a data structure that defines the **event data** attributes.

### Event Handler

Receives a persisted event and perform actions in the **read side** such as to update the projection for
an individual aggregate. Another usage is to build a new command and send to the Command Hanlder when
specific events should trigger a new cycle.

### Projection

It represents the current state of an individual aggregate (_User ID: 123456_, for example) after
replaying all events. Your application reads/queries data from the projection, that is similar to a
persisted cache.

### Event Store

All events from _all aggregates_ are stored in the Event Store. The Event Store uses the Port/Adapter
design pattern so through configuration you can define which adapter your application will use to store
the events. Currently, Incident comes with two adapters, an `InMemory` to be used as playground and a
`Postgres` one.

### Projection Store

Very similar to the Event Store, the Projection Store uses the Port/Adapter design pattern so through
configuration you can define which adapter your application will use to store the aggregate projections.
Currently, Incident comes with two adapters, an `InMemory` to be used as playground and a `Postgres` one.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `incident` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:incident, "~> 0.6.0"}
  ]
end
```

## Usage

`Incident` will be added as part of the application supervision tree, configuring the the adapters for the
**Event Store** and the **Projection Store**.

### With Postgres Adapters

The Postgres adapter uses `Ecto` behind the scenes so a lot of its configuration it is simply how you should
configure a Postgres database for any application using Ecto.

**There will be two Ecto Repos**, one for the events and another one for the projections.

_Optionally, you can even define two different databases, so the events database will contain only one
table (events) and the projections database will contain one table fore each projection type._

Add the Ecto Repo modules for both databases:

```elixir
defmodule AppName.EventStoreRepo do
  use Ecto.Repo,
    otp_app: :app_name,
    adapter: Ecto.Adapters.Postgres
end

defmodule AppName.ProjectionStoreRepo do
  use Ecto.Repo,
    otp_app: :app_name,
    adapter: Ecto.Adapters.Postgres
end

```

In your application `config.exs` specify the repositories:

```elixir
config :app_name, ecto_repos: [AppName.EventStoreRepo, AppName.ProjectionStoreRepo]
```

In your application `dev|test|prod.exs` (the example below defines two databases but it could be only one):

```elixir
config :app_name, AppName.EventStoreRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "app_name_event_store_dev"

config :app_name, AppName.ProjectionStoreRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "app_name_projection_store_dev"
```

Create the application databases running the Ecto mix task:

```
mix ecto.create
```

Use the Incident Mix Task below to generate the `events` and `aggregate_locks` table migrations, after
that, run the migration task:

```
mix incident.postgres.init -r AppName.EventStoreRepo
mix ecto.migrate
```

_The migrations and schemas for the projections will depend on your application domains and it follows
the same process for any Ecto Migration._

Add `Incident` in the `application.ex`, adding into the application supervision tree:

```
defmodule AppName.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    config = %{
      event_store: %{
        adapter: :postgres,
        options: [repo: AppName.EventStoreRepo]
      },
      projection_store: %{
        adapter: :postgres,
        options: [repo: AppName.ProjectionStoreRepo]
      }
    }

    children = [
      AppName.EventStoreRepo,
      AppName.ProjectionStoreRepo,
      {Incident, config}
    ]

    opts = [strategy: :one_for_one, name: AppName.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### With InMemory Adapters

In case of `InMemory` adapters that use `Agent` there is no need for any `Ecto` configuration so it is simply added`Incident` to the application supervision tree:

```
defmodule AppName.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    config = %{
      event_store: %{
        adapter: :in_memory,
        options: []
      },
      projection_store: %{
        adapter: :in_memory,
        options: [
          initial_state: %{AppName.Projections.ProjectionName => []}
        ]
      }
    }

    children = [
      {Incident, config}
    ]

    opts = [strategy: :one_for_one, name: AppName.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Planned Next Steps

The list below is the upcoming enhacements or fixes, it will grow as the library is being developed.

- [ ] allow Incident to be used by more than one application within the umbrella, if needed;
- [ ] add Telemetry module and trigger telemetry events;
- [ ] add Event Snapshots to improve performance for aggregates with long event history;
- [ ] run migrations when using `mix incident.postgres.init` for `Postgres` adapter;
- [ ] allow custom error modules to be used and incorporate as part of the contract in some components;

## Contributing

We appreciate any contribution to Incident. Please see the [Code of Conduct](https://github.com/pedroassumpcao/incident/blob/master/CODE_OF_CONDUCT.md) and [Contributing](https://github.com/pedroassumpcao/incident/blob/master/CONTRIBUTING.md) guides.

## Documentation

The full documentation can be found at [https://hexdocs.pm/incident](https://hexdocs.pm/incident).

