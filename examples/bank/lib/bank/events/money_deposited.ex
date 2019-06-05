defmodule Bank.Events.MoneyDeposited do
  defstruct [:aggregate_id, :amount, :version]
end
