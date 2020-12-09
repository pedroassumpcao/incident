defmodule Bank.Commands.OpenAccount do
  @moduledoc """
  Open Account command using basic Elixir struct with custom validation.
  """

  @behaviour Incident.Command

  defstruct [:aggregate_id]

  @impl true
  def valid?(command) do
    not is_nil(command.aggregate_id)
  end
end
