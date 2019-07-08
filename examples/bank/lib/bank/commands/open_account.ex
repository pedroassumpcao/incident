defmodule Bank.Commands.OpenAccount do
  @moduledoc """
  Open Account command using basic Elixir struct with custom validation.
  """

  @behaviour Incident.Command

  defstruct [:account_number]

  @impl true
  def valid?(command) do
    not is_nil(command.account_number)
  end
end
