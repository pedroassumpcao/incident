defmodule Incident.EventStoreTest do
  use ExUnit.Case

  alias Ecto.UUID

  alias Incident.EventStore
  alias Incident.EventStore.InMemory.Event

  defmodule CounterAdded do
    defstruct [:aggregate_id, :amount, :version]
  end

  defmodule CounterRemoved do
    defstruct [:aggregate_id, :amount, :version]
  end

  setup do
    config = %{
      event_store: %{
        adapter: :in_memory,
        options: []
      },
      projection_store: %{
        adapter: :in_memory,
        options: []
      }
    }

    start_supervised!({Incident, config})
    :ok
  end

  @aggregate_id UUID.generate()

  describe "append/1" do
    test "appends a new event into the event store" do
      event_added = %CounterAdded{aggregate_id: @aggregate_id, amount: 5, version: 1}
      event_removed = %CounterRemoved{aggregate_id: @aggregate_id, amount: 4, version: 2}

      assert {:ok, %Event{}} = EventStore.append(event_added)
      assert {:ok, %Event{}} = EventStore.append(event_removed)
    end
  end

  describe "get/1" do
    test "returns a list of events for an aggregate id in order" do
      event_added = %CounterAdded{aggregate_id: @aggregate_id, amount: 3, version: 1}
      event_removed = %CounterRemoved{aggregate_id: @aggregate_id, amount: 1, version: 2}
      EventStore.append(event_added)
      EventStore.append(event_removed)

      assert [%Event{version: 1}, %Event{version: 2}] = EventStore.get(@aggregate_id)
    end

    test "returns an empty list when no events are found" do
      assert [] = EventStore.get(UUID.generate())
    end
  end

  describe "acquire_lock/1" do
    test "attempts to acquire a lock for the aggregate" do
      assert :ok = EventStore.acquire_lock(@aggregate_id)
    end
  end

  describe "release_lock/1" do
    test "releases an aggregate lock" do
      assert :ok = EventStore.acquire_lock(@aggregate_id)
      assert :ok = EventStore.release_lock(@aggregate_id)
      assert :ok = EventStore.acquire_lock(@aggregate_id)
    end
  end
end
