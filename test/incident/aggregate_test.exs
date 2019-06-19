defmodule Incident.AggregateTest do
  use ExUnit.Case, async: true

  alias Ecto.UUID

  defmodule AddCounter do
    defstruct [:aggregate_id, :amount, :version]
  end

  defmodule CounterAdded do
    defstruct [:aggregate_id, :amount, :version]
  end

  defmodule Counter do
    @behaviour Incident.Aggregate

    @impl true
    def execute(%AddCounter{}), do: :ok

    def execute(_invalid_command), do: {:error, :invalid_command}

    @impl true
    def apply(%CounterAdded{} = event, state) do
      %{state | amount: state.amount + event.amount, version: event.version}
    end
  end

  @aggregate_id UUID.generate()

  describe "execute/1" do
    test "returns `:ok` if the command is successfully exectued" do
      assert :ok =
               Counter.execute(%AddCounter{aggregate_id: @aggregate_id, amount: 1, version: 1})
    end

    test "returns an error and reason if the command can't be executed" do
      assert {:error, :invalid_command} =
               Counter.execute(%{aggregate_id: @aggregate_id, amount: 1, version: 1})
    end
  end

  describe "apply/2" do
    test "applies the events and returns the new state" do
      state = %{aggregate_id: @aggregate_id, amount: 1, version: 1}
      event = %CounterAdded{aggregate_id: @aggregate_id, amount: 5, version: 2}

      assert %{aggregate_id: @aggregate_id, amount: 6, version: 2} = Counter.apply(event, state)
    end
  end
end
