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

  describe "release_lock/3" do
    test "releases the lock when `aggregate_id` and `owner_id` match" do
      {:ok, pid} = LockManager.start_link()
      owner_id = :erlang.phash2(self())
      assert :ok = LockManager.acquire_lock(pid, @aggregate_id, owner_id)
      assert {:error, :already_locked} = LockManager.acquire_lock(pid, @aggregate_id, owner_id)
      assert :ok = LockManager.release_lock(pid, @aggregate_id, owner_id)
      assert :ok = LockManager.acquire_lock(pid, @aggregate_id, owner_id)
    end
  end

  describe "acquire_lock/3" do
    test "returns `:ok` when lock is acquired" do
      {:ok, pid} = LockManager.start_link()
      owner_id = :erlang.phash2(self())
      assert :ok = LockManager.acquire_lock(pid, @aggregate_id, owner_id)
    end

    test "returns `:ok` when lock exist but it is expired" do
      {:ok, pid} = LockManager.start_link(timeout_ms: 0)
      owner_id = :erlang.phash2(self())
      assert :ok = LockManager.acquire_lock(pid, @aggregate_id, owner_id)
      assert :ok = LockManager.acquire_lock(pid, @aggregate_id, owner_id)
    end

    test "returns `{:eror, :already_locked}` when lock is in use" do
      {:ok, pid} = LockManager.start_link()
      owner_id = :erlang.phash2(self())
      assert :ok = LockManager.acquire_lock(pid, @aggregate_id, owner_id)

      assert {:error, :already_locked} = LockManager.acquire_lock(pid, @aggregate_id, owner_id)
    end
  end
end
