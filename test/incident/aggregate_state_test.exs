defmodule Incident.AggregateStateTest do
  use ExUnit.Case

  alias Ecto.UUID

  defmodule Counter do
    @behaviour Incident.Aggregate

    @impl true
    def execute(_command), do: :ok

    @impl true
    def apply(%{aggregate_id: aggregate_id, event_data: event_data}, %{total: total} = state) do
      %{state | aggregate_id: aggregate_id, total: total + event_data["amount"]}
    end
  end

  defmodule CounterState do
    use Incident.AggregateState, aggregate: Counter, initial_state: %{aggregate_id: nil, total: 0}
  end

  defmodule CounterAdded do
    defstruct [:aggregate_id, :amount, :version]
  end

  setup do
    config = [
      event_store: :in_memory,
      event_store_options: [],
      projection_store: :in_memory,
      projection_store_options: []
    ]

    start_supervised!({Incident, config})
    :ok
  end

  @aggregate_id UUID.generate()

  describe "get/1" do
    test "returns the aggregate initial state when no event happened yet" do
      assert %{aggregate_id: nil, total: 0} = CounterState.get(UUID.generate())
    end

    test "returns the aggregate state after applying all events" do
      event1 = %CounterAdded{aggregate_id: @aggregate_id, amount: 1, version: 1}
      Incident.EventStore.append(event1)
      assert %{aggregate_id: @aggregate_id, total: 1} = CounterState.get(@aggregate_id)

      event2 = %CounterAdded{aggregate_id: @aggregate_id, amount: 3, version: 2}
      Incident.EventStore.append(event2)
      assert %{aggregate_id: @aggregate_id, total: 4} = CounterState.get(@aggregate_id)

      event3 = %CounterAdded{aggregate_id: @aggregate_id, amount: 2, version: 3}
      event4 = %CounterAdded{aggregate_id: @aggregate_id, amount: 10, version: 4}
      Incident.EventStore.append(event3)
      Incident.EventStore.append(event4)
      assert %{aggregate_id: @aggregate_id, total: 16} = CounterState.get(@aggregate_id)
    end
  end
end
