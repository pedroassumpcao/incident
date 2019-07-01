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
      Receives the command, validates it and executes it through the aggregate.
      """
      @spec receive(struct) :: :ok | {:error, atom}
      def receive(command) do
        if valid?(command) do
          unquote(aggregate).execute(command)
        else
          {:error, :invalid_command}
        end
      end

      def valid?(_command), do: true
    end
  end
end
