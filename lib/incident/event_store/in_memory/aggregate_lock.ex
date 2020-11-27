defmodule Incident.EventStore.InMemory.AggregateLock do
  @moduledoc """
  Defines the data structure for an aggregate lock for the in memory adapter.

  All fields are required.
  """

  @type t :: %__MODULE__{
          id: pos_integer | nil,
          aggregate_id: String.t() | nil,
          owner_id: pos_integer() | nil,
          valid_until: DateTime.t() | nil
        }

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:aggregate_id, :string)
    field(:owner_id, :integer)
    field(:valid_until, :utc_datetime_usec)
  end

  @required_fields ~w(aggregate_id owner_id valid_until)a

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(record, params \\ %{}) do
    record
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
