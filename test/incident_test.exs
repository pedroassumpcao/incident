defmodule IncidentTest do
  use ExUnit.Case, async: true

  describe "start_link/1" do
    test "starts the supervision tree when configuration is valid" do
      config = [
        event_store: :postgres,
        event_store_options: [
          repo: Incident.EventStore.TestRepo
        ],
        projection_store: :postgres,
        projection_store_options: [
          repo: Incident.ProjectionStore.TestRepo
        ]
      ]

      start_supervised!({Incident, config})

      assert [
               {Incident.ProjectionStore, _pid1, :worker, [Incident.ProjectionStore]},
               {Incident.EventStore, _pid2, :worker, [Incident.EventStore]}
             ] = Supervisor.which_children(Incident.Supervisor)
    end

    test "raises if :event_store is not provided" do
      config = [
        projection_store: :postgres,
        projection_store_options: [
          repo: Bank.ProjectionStoreRepo
        ]
      ]

      assert_raise(ArgumentError, ~r/Event Store adapter is required/, fn ->
        Incident.start_link(config)
      end)
    end

    test "raises if :projectin_store is not provided" do
      config = [
        event_store: :postgres,
        event_store_options: [
          repo: Bank.EventStoreRepo
        ]
      ]

      assert_raise(ArgumentError, ~r/Projection Store adapter is required/, fn ->
        Incident.start_link(config)
      end)
    end

    test "raises if invalid configuration is provided" do
      config = [
        event_store: :unknown,
        event_store_options: [],
        projection_store: :unknown,
        projection_store_options: []
      ]

      assert_raise(ArgumentError, ~r/The options are :postgres and :in_memory/, fn ->
        Incident.start_link(config)
      end)
    end
  end
end
