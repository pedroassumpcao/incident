defmodule Bank.Commands.OpenAccount do
  @behaviour Incident.Command

  defstruct [:account_number]

  @impl true
  def valid?(_) do
    true
  end
end
