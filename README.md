# Incident

Event Sourcing and CQRS in Elixir abstractions.

Special thanks to my friend [Paulo Gonzalez](https://github.com/pdgonzalez872) for the name suggestion for this library.

## Goals

* incentivize the usage of **Event Sourcing** and **CQRS** as good choice for domains that can leverage the main benefits of this design pattern;
* serve as guidance when using Event Sourcing in your system;
* leverage functions and reducers for executing commands and applying events;
* allow customization for fine-grained needs without compromising the principles;

## Event Sourcing and CQRS

In a nutshell, Event Sourcing ensures that all changes to application state are stored as a sequence of events. But if you are new to **Event Sourcing** and **CQRS** I highly recommend watch [Greg Young's presentation at Code on the Beach 2014](https://www.youtube.com/watch?v=JHGkaShoyNs) before moving forward.

## Main Components

* **Command** is a data structure with basic validation;
* **Command Handler** is the entry point of a command in the write side, it performs basic command validation and executes the command through the aggregate;
* **Aggregate** only defines its business logic to execute a command and apply an event, but not its state;
* **Aggregate State** is defined by playing all the events through Aggregate business logic;
* **Event** is a data structure;
* **Event Handler** receives a persisted event and performs the actions in the read side;
* **Event Store** and **Projection Store** are swappable persistence layers to allow different technologies over time;
* **Projection** can be rebuilt based on the persisted events and on the same Aggregate business logic;

## Planned Next Steps

The list below is the upcoming enhacements or fixes, it will grow as the library is being developed.

- [ ] add more commands and events to the example app;
- [ ] add Mix task to generate Postgres projections;
- [ ] add error modules;
- [ ] add Process Managers to orchestrate more complex business logic or side effects, with rollback actions;

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `incident` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:incident, "~> 0.3.0"}
  ]
end
```

## Configuration

### Event Store and Projection Store Setup

Configure `incident` **Event Store** and **Projection Store** adapters and some options. The options will be passed in during the adapter initialization.

#### In Memory Adapter

The goal of using the In Memory Adapter is to provide a quick way to store events and projections,
as a playground tool. **This adapter is not suppose to be used in a real application.**

```elixir
config :incident, :event_store, adapter: Incident.EventStore.InMemoryAdapter,
  options: [
    initial_state: []
]

config :incident, :projection_store, adapter: Incident.ProjectionStore.InMemoryAdapter,
  options: [
    initial_state: %{}
]
```

#### Postgres Adapter

The Postgres adapter uses `Ecto` behind the scenes so a lot of its configuration it is simply
how you should configure a Postgres database for any application using Ecto.

There will be two databases, one to store the events and another one to be used by the projections.
The events database will contain only one table (events) and the projections database will contain
one table fore each projection type.

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

In your application `dev|test|prod.exs`:

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

config :incident, :event_store, adapter: Incident.EventStore.PostgresAdapter,
  options: [
    repo: AppName.EventStoreRepo
  ]

config :incident, :projection_store, adapter: Incident.ProjectionStore.PostgresAdapter,
  options: [
    repo: AppName.ProjectionStoreRepo
  ]
```

Create the application databases running the Ecto mix task:

```
mix ecto.create
```

Use the Incident Mix task to generate the events table migration, and run the migration:

```
mix incident.postgres.init -r AppName.EventStoreRepo
mix ecto.migrate
```

The migrations and schemas for the projections will depend on your application domains.

## Getting Started

There is an [example application](https://github.com/pedroassumpcao/incident/tree/master/examples/bank) that implements a **Bank** application for reference, including all the details and usage in **IEx** as well.

It also contains projections specific to the application domain with migration and schemas defined.

This example application will give you all the details in how to use **Incident**, including integration tests.

## Documentation

The full documentation can be found at [https://hexdocs.pm/incident](https://hexdocs.pm/incident).

