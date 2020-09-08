defmodule Bank.Commands.InitiateTransfer do
  @moduledoc """
  Initiate Transfer command using `Ecto.Schema` and `Ecto.Changeset` to define and validate fields.
  """

  @behaviour Incident.Command

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:aggregate_id, :string)
    field(:source_account_number, :string)
    field(:destination_account_number, :string)
    field(:amount, :integer)
  end

  @required_fields ~w(aggregate_id source_account_number destination_account_number amount)a

  @impl true
  def valid?(command) do
    data = Map.from_struct(command)

    %__MODULE__{}
    |> cast(data, @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:amount, greater_than: 0)
    |> Map.get(:valid?)
  end
end
