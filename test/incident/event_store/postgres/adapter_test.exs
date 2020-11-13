defmodule Incident.EventStore.Postgres.AdapterTest do
  use Incident.RepoCase, async: true

  alias Ecto.UUID

  alias Incident.EventStore.{Postgres.Adapter, Postgres.Event, TestRepo}

  setup do
    Adapter.start_link(repo: TestRepo)

    on_exit(fn ->
      Application.stop(:incident)
      {:ok, _apps} = Application.ensure_all_started(:incident)
    end)
  end

  defmodule CounterAdded do
    defstruct [:aggregate_id, :amount, :version]
  end

  defmodule CounterRemoved do
    defstruct [:aggregate_id, :amount, :version]
  end

  @aggregate_id UUID.generate()

  describe "append/1" do
    test "appends a new event into the event store" do
      event_added = %CounterAdded{aggregate_id: @aggregate_id, amount: 5, version: 1}
      event_removed = %CounterRemoved{aggregate_id: @aggregate_id, amount: 4, version: 2}

      assert {:ok, %Event{}} = Adapter.append(event_added)
      assert {:ok, %Event{}} = Adapter.append(event_removed)
    end

    test "does not append a new event into the event store when event is invalid" do
      event = %CounterAdded{aggregate_id: @aggregate_id, amount: 5, version: nil}

      assert {:error, %Ecto.Changeset{valid?: false}} = Adapter.append(event)
    end
  end

  describe "get/1" do
    test "returns a list of events for an aggregate id in order" do
      event_added = %CounterAdded{aggregate_id: @aggregate_id, amount: 3, version: 1}
      event_removed = %CounterRemoved{aggregate_id: @aggregate_id, amount: 1, version: 2}
      Adapter.append(event_added)
      Adapter.append(event_removed)

      assert [%Event{version: 1}, %Event{version: 2}] = Adapter.get(@aggregate_id)
    end

    test "returns an empty list when no events are found" do
      assert [] = Adapter.get(UUID.generate())
    end
  end
end
