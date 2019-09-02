defmodule Bank.Projections.BankAccount do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:aggregate_id, :string)
    field(:account_number, :string)
    field(:version, :integer)
    field(:balance, :integer)
    field(:event_id, :string)
    field(:event_date, :utc_datetime_usec)
  end
end
