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

