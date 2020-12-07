defmodule BankPostgresConcurrencyTest do
  use Bank.RepoCase

  alias Bank.{BankAccountCommandHandler, TransferCommandHandler}
  alias Bank.Commands.{DepositMoney, OpenAccount, RequestTransfer, WithdrawMoney}
  alias Bank.Projections.{BankAccount, Transfer}
  alias Ecto.UUID

  @default_amount 100
  @withdraw_amount 24
  @account_number UUID.generate()
  @account_number2 UUID.generate()
  @command_open_account %OpenAccount{aggregate_id: @account_number}
  @command_deposit_money %DepositMoney{aggregate_id: @account_number, amount: @default_amount}
  @command_withdraw_money %WithdrawMoney{aggregate_id: @account_number, amount: @withdraw_amount}

  describe "simple bank account operations with race condition" do
    # Attempts to perform 5 money withdrawals concurrently, only 4 are successful
    # because of account balance.
    test "failing to withdraw more money than the account balance" do
      BankAccountCommandHandler.receive(@command_open_account)
      BankAccountCommandHandler.receive(@command_deposit_money)

      Enum.map(1..5, fn _x ->
        Task.async(fn ->
          BankAccountCommandHandler.receive(@command_withdraw_money)
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
      assert bank_account.balance == @default_amount - money_withdrawn_events * @withdraw_amount
    end
  end

  describe "transfering money from one account to another with race condition" do
    @transfer_amount 24
    @transfers 5

    setup do
      BankAccountCommandHandler.receive(@command_open_account)
      BankAccountCommandHandler.receive(@command_deposit_money)

      BankAccountCommandHandler.receive(%{
        @command_open_account
        | aggregate_id: @account_number2
      })

      :ok
    end

    # Attempts to perform 5 money transfers concurrently, only 4 are successful
    # because of source account balance.
    test "transfer money from account to another when there is enough balance" do
      command_request_transfer = %RequestTransfer{
        aggregate_id: nil,
        source_account_number: @account_number,
        destination_account_number: @account_number2,
        amount: @transfer_amount
      }

      Enum.map(1..@transfers, fn _x ->
        Task.async(fn ->
          TransferCommandHandler.receive(%{command_request_transfer | aggregate_id: Ecto.UUID.generate()})
        end)
      end)
      |> Enum.each(fn task ->
        Task.await(task, 10000)
      end)

      transfers = Incident.ProjectionStore.all(Transfer)
      assert Enum.count(transfers) == @transfers

      Enum.each(transfers, fn transfer ->
        assert transfer.aggregate_id
        assert transfer.source_account_number == @account_number
        assert transfer.destination_account_number == @account_number2
        assert transfer.amount == @transfer_amount
      end)

      bank_accounts = Incident.ProjectionStore.all(BankAccount)
      source_bank_account = Enum.find(bank_accounts, &(&1.aggregate_id == @account_number))
      destination_bank_account = Enum.find(bank_accounts, &(&1.aggregate_id == @account_number2))

      assert source_bank_account.balance == 4
      assert destination_bank_account.balance == @transfer_amount * (@transfers - 1)
    end
  end
end
