defmodule Incident.EventStore.InMemory.LockManagerTest do
  use ExUnit.Case

  alias Incident.EventStore.InMemory.LockManager

  @aggregate_id Ecto.UUID.generate()

  describe "acquire_lock/2" do
    test "returns `:ok` when lock is acquired" do
      config = [
        event_store: :in_memory,
        event_store_options: [],
        projection_store: :in_memory,
        projection_store_options: []
      ]

      start_supervised!({Incident, config})

      assert :ok = LockManager.acquire_lock(@aggregate_id)
    end

    test "auto removes the lock after lock timeout" do
      timeout_ms = 200

      config = [
        event_store: :in_memory,
        event_store_options: [
          lock_manager_config: [
            timeout_ms: timeout_ms
          ]
        ],
        projection_store: :in_memory,
        projection_store_options: []
      ]

      start_supervised!({Incident, config})

      assert :ok = LockManager.acquire_lock(@aggregate_id)
      :timer.sleep(timeout_ms + 1)
      assert :ok = LockManager.acquire_lock(@aggregate_id)
    end

    test "returns `:ok` when lock exist but it is expired" do
      config = [
        event_store: :in_memory,
        event_store_options: [
          lock_manager_config: [
            timeout_ms: 0
          ]
        ],
        projection_store: :in_memory,
        projection_store_options: []
      ]

      start_supervised!({Incident, config})

      assert :ok = LockManager.acquire_lock(@aggregate_id)
      assert :ok = LockManager.acquire_lock(@aggregate_id)
    end

    test "returns `:ok` eventually after retries" do
      config = [
        event_store: :in_memory,
        event_store_options: [
          lock_manager_config: [
            timeout_ms: 500,
            jitter_range_ms: 500..600,
            retries: 3
          ]
        ],
        projection_store: :in_memory,
        projection_store_options: []
      ]

      start_supervised!({Incident, config})

      assert :ok = LockManager.acquire_lock(@aggregate_id)
      assert :ok = LockManager.acquire_lock(@aggregate_id)
    end

    test "returns `{:eror, :already_locked}` when lock is in use" do
      config = [
        event_store: :in_memory,
        event_store_options: [
          lock_manager_config: [
            timeout_ms: 1_000,
            jitter_range_ms: 1..10
          ]
        ],
        projection_store: :in_memory,
        projection_store_options: []
      ]

      start_supervised!({Incident, config})

      assert :ok = LockManager.acquire_lock(@aggregate_id)
      assert {:error, :already_locked} = LockManager.acquire_lock(@aggregate_id)
    end

    test "returns `{:eror, :failed_to_lock}` when retries are not positive" do
      config = [
        event_store: :in_memory,
        event_store_options: [
          lock_manager_config: [
            retries: 0
          ]
        ],
        projection_store: :in_memory,
        projection_store_options: []
      ]

      start_supervised!({Incident, config})

      assert {:error, :failed_to_lock} = LockManager.acquire_lock(@aggregate_id)
    end
  end

  describe "release_lock/2" do
    test "releases the lock for the `aggregate_id`" do
      config = [
        event_store: :in_memory,
        event_store_options: [
          lock_manager_config: [
            timeout_ms: 1_000,
            jitter_range_ms: 1..10
          ]
        ],
        projection_store: :in_memory,
        projection_store_options: []
      ]

      start_supervised!({Incident, config})

      assert :ok = LockManager.acquire_lock(@aggregate_id)
      assert {:error, :already_locked} = LockManager.acquire_lock(@aggregate_id)
      assert :ok = LockManager.release_lock(@aggregate_id)
      assert :ok = LockManager.acquire_lock(@aggregate_id)
    end
  end
end
