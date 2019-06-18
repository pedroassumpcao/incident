defmodule Incident.AggregateStateTest do
  use ExUnit.Case, async: true

  setup do
    on_exit(fn ->
      :ok = Application.stop(:incident)

      {:ok, _apps} = Application.ensure_all_started(:incident)
    end)
  end

  defmodule Counter do
    @behaviour Incident.Aggregate

    @impl true
    def execute(_command), do: :ok

    @impl true
    def apply(%{aggregate_id: aggregate_id, event_data: event_data}, %{total: total} = state) do
      %{state | aggregate_id: aggregate_id, total: total + event_data.amount}
    end
  end

  defmodule CounterState do
    use Incident.AggregateState, aggregate: Counter, initial_state: %{aggregate_id: nil, total: 0}
  end

  defmodule CounterAdded do
    defstruct [:aggregate_id, :amount, :version]
  end

  describe "get/1" do
    test "returns the aggregate initial state when no event happened yet" do
      assert %{aggregate_id: nil, total: 0} = CounterState.get("abc")
    end

    test "returns the aggregate state after applying all events" do
      event1 = %CounterAdded{aggregate_id: "abc", amount: 1, version: 1}
      Incident.EventStore.append(event1)
      assert %{aggregate_id: "abc", total: 1} = CounterState.get("abc")

      event2 = %CounterAdded{aggregate_id: "abc", amount: 3, version: 2}
      Incident.EventStore.append(event2)
      assert %{aggregate_id: "abc", total: 4} = CounterState.get("abc")

      event3 = %CounterAdded{aggregate_id: "abc", amount: 2, version: 3}
      event4 = %CounterAdded{aggregate_id: "abc", amount: 10, version: 4}
      Incident.EventStore.append(event3)
      Incident.EventStore.append(event4)
      assert %{aggregate_id: "abc", total: 16} = CounterState.get("abc")
    end
  end
end
