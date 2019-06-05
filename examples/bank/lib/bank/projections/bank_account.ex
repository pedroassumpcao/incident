defmodule Bank.Projections.BankAccount do
  defstruct [:aggregate_id, :account_number, :version, :balance, :event_id, :event_date]
end
