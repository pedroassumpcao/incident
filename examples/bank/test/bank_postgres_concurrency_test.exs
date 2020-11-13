defmodule BankPostgresConcurrencyTest do
  use Bank.RepoCase, async: true

  alias Bank.BankAccountCommandHandler
  alias Bank.Commands.{DepositMoney, OpenAccount, WithdrawMoney}
  alias Bank.Projections.BankAccount
  alias Ecto.UUID

  setup_all do
    on_exit(fn ->
      :ok = Application.stop(:incident)

      {:ok, _apps} = Application.ensure_all_started(:incident)
    end)
  end

  @default_amount 100
  @account_number UUID.generate()
  @command_open_account %OpenAccount{aggregate_id: @account_number}
  @command_deposit_money %DepositMoney{aggregate_id: @account_number, amount: @default_amount}
  @command_withdraw_money %WithdrawMoney{aggregate_id: @account_number, amount: 10}

  describe "simple bank account operations" do

    test "failing to withdraw more money than the account balance against race condition" do
      BankAccountCommandHandler.receive(@command_open_account)
      BankAccountCommandHandler.receive(@command_deposit_money)

      Enum.map(1..5, fn _x ->
        Task.async(fn ->
          BankAccountCommandHandler.receive(@command_withdraw_money)
        end)
      end)
      |> Enum.each(fn task ->
        IO.inspect Task.await(task)
      end)

      # :timer.sleep(500)
      # events = Incident.EventStore.get(@account_number)
      # IO.inspect events

      # assert [bank_account] = Incident.ProjectionStore.all(BankAccount)
      # IO.inspect bank_account
    end
  end
end
