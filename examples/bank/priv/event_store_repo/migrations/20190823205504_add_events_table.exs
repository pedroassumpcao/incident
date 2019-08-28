defmodule Bank.EventStoreRepo.Migrations.AddEventsTable do
  use Ecto.Migration

  def change do
    create table(:events) do
      add(:event_id, :binary_id, null: false)
      add(:aggregate_id, :string, null: false)
      add(:event_type, :string, null: false)
      add(:version, :integer, null: false)
      add(:event_date, :utc_datetime_usec, null: false)
      add(:event_data, :map, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:events, [:aggregate_id]))
    create(index(:events, [:event_type]))
    create(index(:events, [:event_date]))
    create(index(:events, [:version]))
    create constraint(:events, :version_must_be_positive, check: "version > 0")
  end
end
