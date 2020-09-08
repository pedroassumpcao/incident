defmodule Bank.ProjectionStoreRepo.Migrations.CreateTransfersTable do
  use Ecto.Migration

  def change do
    create table(:transfers) do
      add(:aggregate_id, :string, null: false)
      add(:source_account_number, :string, null: false)
      add(:destination_account_number, :string, null: false)
      add(:amount, :integer, null: false)
      add(:status, :string, null: false)
      add(:version, :integer, null: false)
      add(:event_id, :binary_id, null: false)
      add(:event_date, :utc_datetime_usec, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:transfers, [:aggregate_id]))
    create(index(:transfers, [:source_account_number]))
    create(index(:transfers, [:destination_account_number]))
    create(index(:transfers, [:status]))
  end
end
