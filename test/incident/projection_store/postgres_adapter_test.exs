defmodule Incident.ProjectionStore.PostgresAdapterTest do
  use Incident.RepoCase, async: true

  alias Ecto.UUID
  alias Incident.Projections.Counter
  alias Incident.ProjectionStore.{PostgresAdapter, TestRepo}

  setup do
    PostgresAdapter.start_link(repo: TestRepo)

    on_exit(fn ->
      Application.stop(:incident)
      {:ok, _apps} = Application.ensure_all_started(:incident)
    end)
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
              }} = PostgresAdapter.project(Counter, @to_be_projected_data1)

      assert {:ok,
              %Counter{
                aggregate_id: "123456",
                amount: 2,
                version: 2
              }} = PostgresAdapter.project(Counter, @to_be_projected_data2)
    end
  end

  describe "all/1" do
    test "returns a list of all projections" do
      PostgresAdapter.project(Counter, @to_be_projected_data1)
      PostgresAdapter.project(Counter, @to_be_projected_data2)
      PostgresAdapter.project(Counter, @to_be_projected_data3)
      PostgresAdapter.project(Counter, @to_be_projected_data4)

      assert [
               %Counter{aggregate_id: "123456", amount: 3, version: 3},
               %Counter{aggregate_id: "789012", amount: 1, version: 1}
             ] = PostgresAdapter.all(Counter)
    end
  end

  describe "get/2" do
    test "returns the aggregate projection when found" do
      PostgresAdapter.project(Counter, @to_be_projected_data1)

      assert %Counter{aggregate_id: "123456"} = PostgresAdapter.get(Counter, "123456")
    end

    test "returns nil when aggregate is not found in the projection" do
      refute PostgresAdapter.get(Counter, "123456")
    end
  end
end
