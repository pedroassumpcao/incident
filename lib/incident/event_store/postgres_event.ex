defmodule Incident.EventStore.PostgresEvent do
  @moduledoc """
  Defines the data structure for any event for the Postgres adapter.

  All fields are required.
  """

  @type t :: %__MODULE__{
          id: pos_integer | nil,
          event_id: String.t() | nil,
          aggregate_id: String.t() | nil,
          event_type: String.t() | nil,
          version: pos_integer | nil,
          event_date: DateTime.t() | nil,
          event_data: map | nil,
          inserted_at: DateTime.t() | nil
        }

  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]
  schema "events" do
    field(:event_id, :binary_id)
    field(:aggregate_id, :string)
    field(:event_type, :string)
    field(:version, :integer)
    field(:event_date, :utc_datetime_usec)
    field(:event_data, :map)

    timestamps(updated_at: false)
  end

  @required_fields ~w(event_id aggregate_id event_type version event_date event_data)a

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(record, params \\ %{}) do
    record
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:version, greater_than: 0)
  end
end
