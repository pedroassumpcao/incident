defmodule Incident.ProjectionStoreTest do
  use ExUnit.Case

  alias Incident.ProjectionStore

  setup do
    Application.stop(:incident)

    projection_store_config = [
      adapter: Incident.ProjectionStore.InMemoryAdapter,
      options: [
        initial_state: %{counters: []}
      ]
    ]

    Application.put_env(:incident, :projection_store, projection_store_config)
    {:ok, _apps} = Application.ensure_all_started(:incident)

    on_exit(fn ->
      Application.stop(:incident)
      {:ok, _apps} = Application.ensure_all_started(:incident)
    end)
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
end
