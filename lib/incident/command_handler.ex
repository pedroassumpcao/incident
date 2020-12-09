defmodule Incident.CommandHandler do
  @moduledoc """
  Defines a Command Handler that receives a command to:
  - ensure that the command data is valid based on the command validations;
  - executes the command using the aggregate;
  """

  defmacro __using__(opts) do
    aggregate = Keyword.get(opts, :aggregate)
    event_handler = Keyword.get(opts, :event_handler)

    quote do
      import Incident.CommandHandler

      alias Incident.EventStore

      @doc """
      Receives the command struct, validates it and executes it through the aggregate.

      After receiving the new event and aggregate state from the aggregate it attemps to:
      - the event is persisted in the Event Store;
      - the persisted event is broadcasted to the Event Handler;

      Returns an error if:
      - an invalid command is sent;
      - event can't be persisted in the Event Store;
      - event can't be broadcasted to the Event Handler;

      """
      @spec receive(struct) :: {:ok, struct} | {:error, atom | struct | String.t()}
      def receive(command) do
        command_module = command.__struct__

        with true <- command_module.valid?(command),
             :ok <- EventStore.acquire_lock(command.aggregate_id, self()),
             {:ok, new_event, state} <- unquote(aggregate).execute(command),
             {:ok, persisted_event} <- EventStore.append(new_event),
             :ok <- EventStore.release_lock(command.aggregate_id, self()),
             {:ok, _projected_event} <- unquote(event_handler).listen(persisted_event, state) do
          {:ok, persisted_event}
        else
          false -> {:error, :invalid_command}
          {:error, _reason} = error -> error
        end
      end
    end
  end
end
