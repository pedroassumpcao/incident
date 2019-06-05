defmodule Bank.Events.AccountOpened do
  defstruct [:aggregate_id, :account_number, :version]
end
