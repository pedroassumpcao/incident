defmodule BankPostgresConcurrencyTest do
  use Bank.RepoCase

  alias Bank.BankAccountCommandHandler
  alias Bank.Commands.{DepositMoney, OpenAccount, WithdrawMoney}
  alias Bank.Projections.BankAccount
  alias Ecto.UUID

  @default_amount 100
  @withdraw_amount 24
  @account_number UUID.generate()
  @command_open_account %OpenAccount{aggregate_id: @account_number}
  @command_deposit_money %DepositMoney{aggregate_id: @account_number, amount: @default_amount}
  @command_withdraw_money %WithdrawMoney{aggregate_id: @account_number, amount: @withdraw_amount}

  describe "simple bank account operations with race condition" do
    test "failing to withdraw more money than the account balance" do
      BankAccountCommandHandler.receive(@command_open_account)
      BankAccountCommandHandler.receive(@command_deposit_money)

      Enum.map(1..5, fn _x ->
        Task.async(fn ->
          Bank.BankAccountCommandHandler.receive(@command_withdraw_money)
        end)
      end)
      |> Enum.each(fn task ->
        Task.await(task, 10000)
      end)

      money_withdrawn_events =
        @account_number
        |> Incident.EventStore.get()
        |> Enum.filter(&(&1.event_type == "MoneyWithdrawn"))
        |> Enum.count()

      assert money_withdrawn_events == 4
      assert [bank_account] = Incident.ProjectionStore.all(BankAccount)
      assert bank_account.balance == @default_amount - (money_withdrawn_events * @withdraw_amount)
    end
  end
end
