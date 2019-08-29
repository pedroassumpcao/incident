defmodule Incident.EventStore.PostgresEventTest do
  use Incident.DataCase, async: true

  alias Ecto.UUID
  alias Incident.EventStore.PostgresEvent

  @valid_params %{
    event_id: UUID.generate(),
    aggregate_id: UUID.generate(),
    event_type: "SomethingHappened",
    version: 1,
    event_date: DateTime.utc_now(),
    event_data: %{}
  }

  describe "changeset/2" do
    test "returns a valid changeset when all fields are valid" do
      changeset = PostgresEvent.changeset(%PostgresEvent{}, @valid_params)

      assert changeset.valid?
    end

    test "returns an error when a required field is not present" do
      changeset = PostgresEvent.changeset(%PostgresEvent{}, %{})

      refute changeset.valid?
      assert %{event_id: ["can't be blank"]} = errors_on(changeset)
      assert %{aggregate_id: ["can't be blank"]} = errors_on(changeset)
      assert %{event_type: ["can't be blank"]} = errors_on(changeset)
      assert %{event_date: ["can't be blank"]} = errors_on(changeset)
      assert %{event_data: ["can't be blank"]} = errors_on(changeset)
      assert %{version: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns an error when a field is set with a wront type" do
      invalid_params = Map.merge(@valid_params, %{event_date: "2010-04-11"})
      changeset = PostgresEvent.changeset(%PostgresEvent{}, invalid_params)

      refute changeset.valid?
      assert %{event_date: ["is invalid"]} = errors_on(changeset)
    end
  end
end
