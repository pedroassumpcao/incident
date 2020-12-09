defmodule Incident.ProjectionStore.Postgres.AdapterTest do
  use Incident.RepoCase

  alias Ecto.UUID
  alias Incident.Projections.Counter
  alias Incident.ProjectionStore.Postgres.Adapter

  setup do
    config = %{
      event_store: %{
        adapter: :postgres,
        options: [repo: Incident.EventStore.TestRepo]
      },
      projection_store: %{
        adapter: :postgres,
        options: [repo: Incident.ProjectionStore.TestRepo]
      }
    }

    start_supervised!({Incident, config})
    :ok
  end

  @to_be_projected_data1 %{
    aggregate_id: "123456",
    amount: 1,
    version: 1,
    event_id: UUID.generate(),
    event_date: DateTime.utc_now()
  }
  @to_be_projected_data2 %{
    aggregate_id: "123456",
    amount: 2,
    version: 2,
    event_id: UUID.generate(),
    event_date: DateTime.utc_now()
  }
  @to_be_projected_data3 %{
    aggregate_id: "123456",
    amount: 3,
    version: 3,
    event_id: UUID.generate(),
    event_date: DateTime.utc_now()
  }
  @to_be_projected_data4 %{
    aggregate_id: "789012",
    amount: 1,
    version: 1,
    event_id: UUID.generate(),
    event_date: DateTime.utc_now()
  }

  describe "project/2" do
    test "projects new data into a projection" do
      assert {:ok,
              %Counter{
                aggregate_id: "123456",
                amount: 1,
                version: 1
              }} = Adapter.project(Counter, @to_be_projected_data1)

      assert {:ok,
              %Counter{
                aggregate_id: "123456",
                amount: 2,
                version: 2
              }} = Adapter.project(Counter, @to_be_projected_data2)
    end
  end

  describe "all/1" do
    test "returns a list of all projections" do
      Adapter.project(Counter, @to_be_projected_data1)
      Adapter.project(Counter, @to_be_projected_data2)
      Adapter.project(Counter, @to_be_projected_data3)
      Adapter.project(Counter, @to_be_projected_data4)

      assert [
               %Counter{aggregate_id: "123456", amount: 3, version: 3},
               %Counter{aggregate_id: "789012", amount: 1, version: 1}
             ] = Adapter.all(Counter)
    end
  end

  describe "get/2" do
    test "returns the aggregate projection when found" do
      Adapter.project(Counter, @to_be_projected_data1)

      assert %Counter{aggregate_id: "123456"} = Adapter.get(Counter, "123456")
    end

    test "returns nil when aggregate is not found in the projection" do
      refute Adapter.get(Counter, "123456")
    end
  end
end
