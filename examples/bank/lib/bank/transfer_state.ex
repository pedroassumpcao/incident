defmodule Bank.TransferState do
  use Incident.AggregateState,
    aggregate: Bank.Transfer,
    initial_state: %{
      aggregate_id: nil,
      source_account_number: nil,
      destination_account_number: nil,
      amount: nil,
      status: nil,
      version: nil,
      updated_at: nil
    }
end
