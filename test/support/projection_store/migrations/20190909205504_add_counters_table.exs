defmodule Bank.ProjectionStoreRepo.Migrations.AddCountersTable do
  use Ecto.Migration

  def change do
    create table(:counters) do
      add(:aggregate_id, :string, null: false)
      add(:amount, :integer, null: false)
      add(:version, :integer, null: false)
      add(:event_id, :binary_id, null: false)
      add(:event_date, :utc_datetime_usec, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:counters, [:aggregate_id]))
  end
end
