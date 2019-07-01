defmodule Incident.CommandHandlerTest do
  use ExUnit.Case, async: true

  alias Ecto.UUID

  defmodule AddCounter do
    defstruct [:aggregate_id, :amount, :version]
  end

  defmodule Counter do
    @behaviour Incident.Aggregate

    @impl true
    def execute(%AddCounter{}), do: :ok

    def execute(_invalid_command), do: {:error, :invalid_command}

    @impl true
    def apply(_event, state), do: state
  end

  defmodule CounterCommandHandler do
    use Incident.CommandHandler, aggregate: Counter
  end

  @aggregate_id UUID.generate()

  describe "receive/1" do
    test "returns `:ok` if the command is successfully executed" do
      assert :ok =
               CounterCommandHandler.receive(%AddCounter{
                 aggregate_id: @aggregate_id,
                 amount: 1,
                 version: 1
               })
    end

    test "returns an error and reason if the command can't be executed" do
      assert {:error, :invalid_command} =
               CounterCommandHandler.receive(%{aggregate_id: @aggregate_id, amount: 1, version: 1})
    end
  end
end
