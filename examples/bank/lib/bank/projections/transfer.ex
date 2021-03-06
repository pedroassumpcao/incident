defmodule Bank.Projections.Transfer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transfers" do
    field(:aggregate_id, :string)
    field(:source_account_number, :string)
    field(:destination_account_number, :string)
    field(:amount, :integer)
    field(:status, :string)
    field(:version, :integer)
    field(:event_id, :binary_id)
    field(:event_date, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end

  @required_fields ~w(aggregate_id source_account_number destination_account_number amount status version event_id event_date)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
