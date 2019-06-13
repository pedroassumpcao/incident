defmodule BankTest do
  use ExUnit.Case

  alias Bank.BankAccount
  alias Bank.Commands.{DepositMoney, OpenAccount}
  alias Ecto.UUID

  setup do
    on_exit(fn ->
      :ok = Application.stop(:incident)

      {:ok, _apps} = Application.ensure_all_started(:incident)
    end)
  end

  @account_number UUID.generate()
  @command_open_account %OpenAccount{account_number: @account_number}
  @command_deposit_money %DepositMoney{aggregate_id: @account_number, amount: 100}

  test "executes an open account command" do
    assert :ok = BankAccount.execute(@command_open_account)

    assert [bank_account] = Incident.ProjectionStore.all(:bank_accounts)
    assert bank_account.aggregate_id == @account_number
    assert bank_account.account_number == @account_number
    assert bank_account.balance == 0
    assert bank_account.version == 1
    assert bank_account.event_date
    assert bank_account.event_id
  end

  test "returns an error when executes an invalid command" do
    assert :ok = BankAccount.execute(@command_open_account)
    assert {:error, :account_already_opened} = BankAccount.execute(@command_open_account)

    assert [bank_account] = Incident.ProjectionStore.all(:bank_accounts)
    assert bank_account.aggregate_id == @account_number
    assert bank_account.account_number == @account_number
    assert bank_account.balance == 0
    assert bank_account.version == 1
    assert bank_account.event_date
    assert bank_account.event_id
  end

  test "executes an open account and deposit money commands" do
    assert :ok = BankAccount.execute(@command_open_account)

    assert [bank_account] = Incident.ProjectionStore.all(:bank_accounts)
    assert bank_account.aggregate_id == @account_number
    assert bank_account.account_number == @account_number
    assert bank_account.balance == 0
    assert bank_account.version == 1
    assert bank_account.event_date
    assert bank_account.event_id

    assert :ok = BankAccount.execute(@command_deposit_money)

    assert [bank_account] = Incident.ProjectionStore.all(:bank_accounts)
    assert bank_account.aggregate_id == @account_number
    assert bank_account.account_number == @account_number
    assert bank_account.balance == 100
    assert bank_account.version == 2
    assert bank_account.event_date
    assert bank_account.event_id

    assert :ok = BankAccount.execute(@command_deposit_money)

    assert [bank_account] = Incident.ProjectionStore.all(:bank_accounts)
    assert bank_account.aggregate_id == @account_number
    assert bank_account.account_number == @account_number
    assert bank_account.balance == 200
    assert bank_account.version == 3
    assert bank_account.event_date
    assert bank_account.event_id
  end
end
