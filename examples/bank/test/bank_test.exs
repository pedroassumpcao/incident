defmodule BankTest do
  use ExUnit.Case

  alias Bank.BankAccount
  alias Bank.Commands.{DepositMoney, OpenAccount}
  alias Ecto.UUID

  test "executes valid commands" do
    command_open_account = %OpenAccount{account_number: UUID.generate()}
    assert :ok = BankAccount.execute(command_open_account)
  end

  test "returns an error when executes an invalid command" do
    command_open_account = %OpenAccount{account_number: UUID.generate()}
    assert :ok = BankAccount.execute(command_open_account)
    assert {:error, :account_already_opened} = BankAccount.execute(command_open_account)
  end

  test "executes multiple valid commands" do
    account_number = UUID.generate()
    command_open_account = %OpenAccount{account_number: account_number}
    assert :ok = BankAccount.execute(command_open_account)
    command_deposit_money = %DepositMoney{aggregate_id: account_number, amount: 100}
    assert :ok = BankAccount.execute(command_deposit_money)
  end
end
