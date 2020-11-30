defmodule Incident.EventStore.InMemory.LockManagerTest do
  use ExUnit.Case

  alias Incident.EventStore.InMemory.LockManager

  setup do
    config = [
      event_store: :in_memory,
      event_store_options: [],
      projection_store: :in_memory,
      projection_store_options: []
    ]

    start_supervised!({Incident, config})
    :ok
  end

  @aggregate_id Ecto.UUID.generate()

  describe "acquire_lock/2" do
    test "returns `:ok` when lock is acquired" do
      LockManager.start_link()

      assert :ok = LockManager.acquire_lock(@aggregate_id)
    end

    test "auto removes the lock after lock timeout" do
      timeout_ms = 200
      LockManager.start_link(timeout_ms: timeout_ms)

      assert :ok = LockManager.acquire_lock(@aggregate_id)
      :timer.sleep(timeout_ms + 1)
      assert :ok = LockManager.acquire_lock(@aggregate_id)
    end

    test "returns `:ok` when lock exist but it is expired" do
      LockManager.start_link(timeout_ms: 0)

      assert :ok = LockManager.acquire_lock(@aggregate_id)
      assert :ok = LockManager.acquire_lock(@aggregate_id)
    end

    test "returns `:ok` eventually after retries" do
      LockManager.start_link(timeout_ms: 500, jitter_range_ms: 500..600, retries: 3)

      assert :ok = LockManager.acquire_lock(@aggregate_id)
      assert :ok = LockManager.acquire_lock(@aggregate_id)
    end

    test "returns `{:eror, :already_locked}` when lock is in use" do
      LockManager.start_link(timeout_ms: 1_000, jitter_range_ms: 1..10)

      assert :ok = LockManager.acquire_lock(@aggregate_id)
      assert {:error, :already_locked} = LockManager.acquire_lock(@aggregate_id)
    end

    test "returns `{:eror, :failed_to_lock}` when retries are not positive" do
      LockManager.start_link(retries: 0)

      assert {:error, :failed_to_lock} = LockManager.acquire_lock(@aggregate_id)
    end
  end

  describe "release_lock/2" do
    test "releases the lock for the `aggregate_id`" do
      LockManager.start_link(timeout_ms: 1_000, jitter_range_ms: 1..10)

      assert :ok = LockManager.acquire_lock(@aggregate_id)
      assert {:error, :already_locked} = LockManager.acquire_lock(@aggregate_id)
      assert :ok = LockManager.release_lock(@aggregate_id)
      assert :ok = LockManager.acquire_lock(@aggregate_id)
    end
  end
end
