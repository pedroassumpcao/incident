defmodule Bank.TransferCommandHandler do
  use Incident.CommandHandler, aggregate: Bank.Transfer, event_handler: Bank.TransferEventHandler
end
