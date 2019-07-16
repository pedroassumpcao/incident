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
      It returns ane error in case of an invalid command.
      """
      @spec receive(struct) :: :ok | {:error, atom}
      def receive(command) do
        command_module = command.__struct__

        with true <- command_module.valid?(command) do
          unquote(aggregate).execute(command)
        else
          false -> {:error, :invalid_command}
        end
      end
    end
  end
end
