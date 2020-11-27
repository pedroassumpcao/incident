defmodule Incident.EventStore.Postgres.AggregateLockTest do
  use Incident.RepoCase, async: true

  alias Ecto.UUID
  alias Incident.EventStore.Postgres.AggregateLock

  @valid_params %{
    aggregate_id: UUID.generate(),
    owner_id: 1,
    valid_until: DateTime.utc_now()
  }

  describe "changeset/2" do
    test "returns a valid changeset when all fields are valid" do
      changeset = AggregateLock.changeset(%AggregateLock{}, @valid_params)

      assert changeset.valid?
    end

    test "returns an error when a required field is not present" do
      changeset = AggregateLock.changeset(%AggregateLock{}, %{})

      refute changeset.valid?
      assert %{aggregate_id: ["can't be blank"]} = errors_on(changeset)
      assert %{owner_id: ["can't be blank"]} = errors_on(changeset)
      assert %{valid_until: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns an error when a field is set with a wront type" do
      invalid_params = Map.merge(@valid_params, %{valid_until: "2010-04-11"})
      changeset = AggregateLock.changeset(%AggregateLock{}, invalid_params)

      refute changeset.valid?
      assert %{valid_until: ["is invalid"]} = errors_on(changeset)
    end
  end
end
