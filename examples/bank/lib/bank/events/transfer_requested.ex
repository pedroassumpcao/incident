defmodule Bank.Events.TransferRequested do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:aggregate_id, :string)
    field(:source_account_number, :string)
    field(:destination_account_number, :string)
    field(:amount, :integer)
    field(:version, :integer)
  end
end
