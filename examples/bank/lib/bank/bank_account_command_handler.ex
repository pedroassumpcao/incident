defmodule Bank.BankAccountCommandHandler do
  use Incident.CommandHandler, aggregate: Bank.BankAccount
end
