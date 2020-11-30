defmodule IncidentTest do
  use ExUnit.Case, async: true

  describe "start_link/1" do
    test "starts the supervision tree when configuration is valid" do
      config = %{
        event_store: %{
          adapter: :postgres,
          options: [
            repo: Incident.EventStore.TestRepo
          ]
        },
        projection_store: %{
          adapter: :postgres,
          options: [
            repo: Incident.ProjectionStore.TestRepo
          ]
        }
      }

      start_supervised!({Incident, config})

      assert [
               {Incident.ProjectionStore, _pid1, :worker, [Incident.ProjectionStore]},
               {Incident.EventStoreSupervisor, _pid2, :supervisor, [Incident.EventStoreSupervisor]}
             ] = Supervisor.which_children(Incident.Supervisor)
    end

    test "raises if :event_store is not provided" do
      config = %{
        projection_store: %{
          adapter: :postgres,
          options: [
            repo: Incident.ProjectionStore.TestRepo
          ]
        }
      }

      assert_raise(RuntimeError, ~r/Event Store adapter is required/, fn ->
        start_supervised!({Incident, config})
      end)
    end

    test "raises if :projection_store is not provided" do
      config = %{
        event_store: %{
          adapter: :postgres,
          options: [
            repo: Incident.EventStore.TestRepo
          ]
        }
      }

      assert_raise(RuntimeError, ~r/Projection Store adapter is required/, fn ->
        start_supervised!({Incident, config})
      end)
    end

    test "raises if invalid configuration is provided" do
      config = %{
        event_store: %{
          adapter: :unknown,
          options: []
        },
        projection_store: %{
          adapter: :unknown,
          options: []
        }
      }

      assert_raise(RuntimeError, ~r/The options are :postgres and :in_memory/, fn ->
        start_supervised!({Incident, config})
      end)
    end
  end
end
