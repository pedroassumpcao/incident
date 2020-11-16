defmodule Incident.ProjectionStoreTest do
  use ExUnit.Case

  alias Incident.ProjectionStore

  setup do
    config = [
      event_store: :in_memory,
      event_store_options: [],
      projection_store: :in_memory,
      projection_store_options: [initial_state: %{counters: []}]
    ]

    start_supervised!({Incident, config})
    :ok
  end

  describe "project/2" do
    test "projects new data into a projection" do
      assert {:ok, %{aggregate_id: "123456", amount: 1}} =
               ProjectionStore.project(:counters, %{aggregate_id: "123456", amount: 1})

      assert {:ok, %{aggregate_id: "123456", amount: 2}} =
               ProjectionStore.project(:counters, %{aggregate_id: "123456", amount: 2})

      assert {:ok, %{aggregate_id: "123456", amount: 3}} =
               ProjectionStore.project(:counters, %{aggregate_id: "123456", amount: 3})
    end
  end

  describe "all/1" do
    test "returns a list of all projections" do
      assert {:ok, %{aggregate_id: "123456", amount: 1}} =
               ProjectionStore.project(:counters, %{aggregate_id: "123456", amount: 1})

      assert {:ok, %{aggregate_id: "789012", amount: 1}} =
               ProjectionStore.project(:counters, %{aggregate_id: "789012", amount: 1})

      assert {:ok, %{aggregate_id: "789012", amount: 2}} =
               ProjectionStore.project(:counters, %{aggregate_id: "789012", amount: 2})

      assert {:ok, %{aggregate_id: "123456", amount: 2}} =
               ProjectionStore.project(:counters, %{aggregate_id: "123456", amount: 2})

      assert {:ok, %{aggregate_id: "789012", amount: 3}} =
               ProjectionStore.project(:counters, %{aggregate_id: "789012", amount: 3})

      assert [
               %{aggregate_id: "123456", amount: 2},
               %{aggregate_id: "789012", amount: 3}
             ] = ProjectionStore.all(:counters)
    end

    test "returns nil if the projection doesn't exist" do
      refute ProjectionStore.all(Incident)
    end
  end

  describe "get/2" do
    test "returns the aggregate projection when found" do
      assert {:ok, %{aggregate_id: "123456", amount: 1}} =
               ProjectionStore.project(:counters, %{aggregate_id: "123456", amount: 1})

      assert %{aggregate_id: "123456", amount: 1} = ProjectionStore.get(:counters, "123456")
    end

    test "returns nil when aggregate is not found in the projection" do
      refute ProjectionStore.get(:counters, "123456")
    end
  end
end
