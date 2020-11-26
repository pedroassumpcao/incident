defmodule Bank.EventStoreRepo.Migrations.CreateAggregateLocksTable do
  use Ecto.Migration

  def change do
    create table(:aggregate_locks, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:aggregate_id, :string, null: false)
      add(:owner_id, :integer, null: false)
      add(:valid_until, :utc_datetime_usec, null: false)
    end

    create(index(:aggregate_locks, [:aggregate_id]))
    create(index(:aggregate_locks, [:aggregate_id, :owner_id]))
    create(index(:aggregate_locks, [:valid_until]))
  end
end