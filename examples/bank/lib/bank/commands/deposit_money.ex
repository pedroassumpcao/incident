defmodule Bank.Commands.DepositMoney do
  @behaviour Incident.Command

  defstruct [:aggregate_id, :amount]

  @impl true
  def valid?(_) do
    true
  end
end
