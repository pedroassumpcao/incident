defmodule Incident.CommandHandler do
  @moduledoc """
  Defines a Command Handler that receives a command to:
  - ensure that the command is valid;
  - executes the command using the aggregate;
  """

  defmacro __using__(opts) do
    aggregate = Keyword.get(opts, :aggregate)

    quote do
      import Incident.CommandHandler

      alias Incident.EventStore

      @doc """
      Receives the command struct, validates it and executes it through the aggregate.
      In case the command is invalid, returns an error.
      """
      @spec receive(struct) :: :ok | {:error, atom}
      def receive(command) do
        command_module = command.__struct__

        if command_module.valid?(command) do
          unquote(aggregate).execute(command)
        else
          {:error, :invalid_command}
        end
      end
    end
  end
end
