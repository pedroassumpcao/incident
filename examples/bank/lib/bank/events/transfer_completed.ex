defmodule Bank.Events.TransferCompleted do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:aggregate_id, :string)
    field(:version, :integer)
  end
end
