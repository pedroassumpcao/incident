# Incident

Event Sourcing and CQRS in Elixir made simple.

## Goals

* incentivize the usage of **Event Sourcing** and **CQRS** as good choice for domains that can leverage the main benefits of this design pattern;
* serve as guidance when using Event Sourcing in your system;
* leverage functions and reducers for executing commands and applying events;
* allow customization for fine-grained needs without compromising the principles;

## Event Sourcing and CQRS

In a nutshell, Event Sourcing ensures that all changes to application state are stored as a sequence of events. But if you are new to **Event Sourcing** and **CQRS** I highly recommend watch [Greg Young's presentation at Code on the Beach 2014](https://www.youtube.com/watch?v=JHGkaShoyNs) before moving forward.

## Main Components

* **Command** is a data structure with basic validation;
* **Event** is a data structure;
* **Aggregate** only defines its business logic to execute a command and apply an event, but not its state;
* **Aggregate State** is defined by playing all the events through Aggregate business logic;
* **Event Store** and **Projection Store** are swappable persistence layers to allow different technologies over time;
* **Projection** can be rebuilt based on the persisted events and on the same Aggregate business logic;

## Roadmap

### Next Steps
- [ ] define behaviour for event handlers;
- [ ] define behaviour for command handlers;
- [ ] use `Ecto.Schema` for command and event data structure;
- [ ] add Postgres as an option for event and projection storage via a built-in Ecto Adapter;

### Done
- [x] create a **Proof of Concept** that can exercise all library components, implementation and confirm goals;
- [x] extract library components from the POC, remove implementation and document the implementation in the `README`;
- [x] add example application within the library as a reference for newcomers;
- [x] publish version `0.1.0` to Hex and make repository public;

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

## Configuration

### Event Store and Projection Store Setup

Configure `incident` **Event Store** and **Projection Store** adapters and if desired, some options. The options will be passed in during the adapter initialization.

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

## Getting Started

There is an [example application](https://github.com/pedroassumpcao/incident/tree/master/examples/bank) that implements a **Bank** application for reference, including all the details and usage in **IEx** as well.

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/incident](https://hexdocs.pm/incident).

