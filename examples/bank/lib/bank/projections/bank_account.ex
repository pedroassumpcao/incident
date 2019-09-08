defmodule Bank.Projections.BankAccount do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bank_accounts" do
    field(:aggregate_id, :string)
    field(:account_number, :string)
    field(:balance, :integer)
    field(:version, :integer)
    field(:event_id, :binary_id)
    field(:event_date, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end

  @required_fields ~w(aggregate_id account_number balance version event_id event_date)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
