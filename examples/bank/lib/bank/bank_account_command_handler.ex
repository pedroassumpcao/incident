defmodule Bank.BankAccountCommandHandler do
  use Incident.CommandHandler,
    aggregate: Bank.BankAccount,
    event_handler: Bank.BankAccountEventHandler
end
