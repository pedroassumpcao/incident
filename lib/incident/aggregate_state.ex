defmodule Incident.AggregateState do
  defmacro __using__(opts) do
    aggregate = Keyword.get(opts, :aggregate)
    initial_state = Keyword.get(opts, :initial_state)

    quote do
      import Incident.AggregateState

      alias Incident.EventStore

      def get(aggregate_id) do
        aggregate_id
        |> EventStore.get()
        |> Enum.reduce(unquote(initial_state), fn event, state ->
          unquote(aggregate).apply(event, state)
        end)
      end
    end
  end
end
