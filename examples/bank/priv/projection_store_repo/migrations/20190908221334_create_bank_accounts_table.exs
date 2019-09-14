defmodule Bank.ProjectionStoreRepo.Migrations.CreateBankAccountsTable do
  use Ecto.Migration

  def change do
    create table(:bank_accounts) do
      add(:aggregate_id, :string, null: false)
      add(:account_number, :string, null: false)
      add(:balance, :integer, null: false)
      add(:version, :integer, null: false)
      add(:event_id, :binary_id, null: false)
      add(:event_date, :utc_datetime_usec, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:bank_accounts, [:aggregate_id]))
  end
end
