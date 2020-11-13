defmodule Incident.EventStore.InMemory.LockManagerTest do
  use ExUnit.Case

  alias Incident.EventStore.InMemory.{Lock, LockManager}

  setup do
    on_exit(fn ->
      Application.stop(:incident)
      {:ok, _apps} = Application.ensure_all_started(:incident)
    end)
  end

  @aggregate_id Ecto.UUID.generate()

  describe "acquire_lock/3" do
    test "returns `:ok` when lock is acquired" do
      {:ok, pid} = LockManager.start_link()

      assert :ok = LockManager.acquire_lock(pid, @aggregate_id)
    end

    test "auto removes the lock after lock timeout" do
      timeout_ms = 200
      {:ok, pid} = LockManager.start_link(timeout_ms: timeout_ms)

      assert :ok = LockManager.acquire_lock(pid, @aggregate_id)
      :timer.sleep(timeout_ms + 1)
      assert :ok = LockManager.acquire_lock(pid, @aggregate_id)
    end

    test "returns `:ok` when lock exist but it is expired" do
      {:ok, pid} = LockManager.start_link(timeout_ms: 0)

      assert :ok = LockManager.acquire_lock(pid, @aggregate_id)
      assert :ok = LockManager.acquire_lock(pid, @aggregate_id)
    end

    test "returns `{:eror, :already_locked}` when lock is in use" do
      {:ok, pid} = LockManager.start_link(timeout_ms: 5_000)

      assert :ok = LockManager.acquire_lock(pid, @aggregate_id)
      assert {:error, :already_locked} = LockManager.acquire_lock(pid, @aggregate_id)
    end
  end

  describe "release_lock/3" do
    test "releases the lock for the `aggregate_id`" do
      {:ok, pid} = LockManager.start_link()

      assert :ok = LockManager.acquire_lock(pid, @aggregate_id)
      assert {:error, :already_locked} = LockManager.acquire_lock(pid, @aggregate_id)
      assert :ok = LockManager.release_lock(pid, @aggregate_id)
      assert :ok = LockManager.acquire_lock(pid, @aggregate_id)
    end
  end
end
