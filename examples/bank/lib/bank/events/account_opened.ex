defmodule Bank.Events.AccountOpened do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:aggregate_id, :string)
    field(:account_number, :string)
    field(:version, :integer)
  end
end
