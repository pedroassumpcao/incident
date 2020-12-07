defmodule Incident.EventStore.Postgres.LockManagerTest do
  use Incident.RepoCase

  alias Incident.EventStore.Postgres.LockManager

  @aggregate_id Ecto.UUID.generate()

  describe "acquire_lock/2" do
    test "returns `:ok` when lock is acquired" do
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
      assert :ok = LockManager.acquire_lock(@aggregate_id, self())
    end

    test "auto removes the lock after lock timeout" do
      timeout_ms = 200

      config = %{
        event_store: %{
          adapter: :postgres,
          options: [
            repo: Incident.EventStore.TestRepo,
            lock_manager_config: [
              timeout_ms: timeout_ms
            ]
          ]
        },
        projection_store: %{
          adapter: :postgres,
          options: [repo: Incident.ProjectionStore.TestRepo]
        }
      }

      start_supervised!({Incident, config})

      assert :ok = LockManager.acquire_lock(@aggregate_id, self())
      :timer.sleep(timeout_ms + 1)
      assert :ok = LockManager.acquire_lock(@aggregate_id, self())
    end

    test "returns `:ok` when lock exist but it is expired" do
      config = %{
        event_store: %{
          adapter: :postgres,
          options: [
            repo: Incident.EventStore.TestRepo,
            lock_manager_config: [
              timeout_ms: 0
            ]
          ]
        },
        projection_store: %{
          adapter: :postgres,
          options: [repo: Incident.ProjectionStore.TestRepo]
        }
      }

      start_supervised!({Incident, config})

      assert :ok = LockManager.acquire_lock(@aggregate_id, self())
      assert :ok = LockManager.acquire_lock(@aggregate_id, self())
    end

    test "returns `:ok` eventually after retries" do
      config = %{
        event_store: %{
          adapter: :postgres,
          options: [
            repo: Incident.EventStore.TestRepo,
            lock_manager_config: [
              timeout_ms: 500,
              jitter_range_ms: 500..600,
              retries: 3
            ]
          ]
        },
        projection_store: %{
          adapter: :postgres,
          options: [repo: Incident.ProjectionStore.TestRepo]
        }
      }

      start_supervised!({Incident, config})

      assert :ok = LockManager.acquire_lock(@aggregate_id, self())
      assert :ok = LockManager.acquire_lock(@aggregate_id, self())
    end

    test "returns `{:eror, :already_locked}` when lock is in use" do
      config = %{
        event_store: %{
          adapter: :postgres,
          options: [
            repo: Incident.EventStore.TestRepo,
            lock_manager_config: [
              timeout_ms: 1_000,
              jitter_range_ms: 1..10
            ]
          ]
        },
        projection_store: %{
          adapter: :postgres,
          options: [repo: Incident.ProjectionStore.TestRepo]
        }
      }

      start_supervised!({Incident, config})

      assert :ok = LockManager.acquire_lock(@aggregate_id, self())
      assert {:error, :already_locked} = LockManager.acquire_lock(@aggregate_id, self())
    end

    test "returns `{:eror, :failed_to_lock}` when retries are not positive" do
      config = %{
        event_store: %{
          adapter: :postgres,
          options: [
            repo: Incident.EventStore.TestRepo,
            lock_manager_config: [
              retries: 0
            ]
          ]
        },
        projection_store: %{
          adapter: :postgres,
          options: [repo: Incident.ProjectionStore.TestRepo]
        }
      }

      start_supervised!({Incident, config})

      assert {:error, :failed_to_lock} = LockManager.acquire_lock(@aggregate_id, self())
    end
  end

  describe "release_lock/2" do
    test "releases the lock for the `aggregate_id`" do
      config = %{
        event_store: %{
          adapter: :postgres,
          options: [
            repo: Incident.EventStore.TestRepo,
            lock_manager_config: [
              timeout_ms: 1_000,
              jitter_range_ms: 1..10
            ]
          ]
        },
        projection_store: %{
          adapter: :postgres,
          options: [repo: Incident.ProjectionStore.TestRepo]
        }
      }

      start_supervised!({Incident, config})

      assert :ok = LockManager.acquire_lock(@aggregate_id, self())
      assert {:error, :already_locked} = LockManager.acquire_lock(@aggregate_id, self())
      assert :ok = LockManager.release_lock(@aggregate_id, self())
      assert :ok = LockManager.acquire_lock(@aggregate_id, self())
    end
  end
end
