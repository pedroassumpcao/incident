defmodule BankInMemoryTest do
  @moduledoc """
  This is an example of integration tests using InMemory adapters. To use InMemory adapters you need to
  change the `application.ex` to define the Incident options in the supervision tree, then run this test:

  ```
  defmodule Bank.Application do
    @moduledoc false

    use Application

    def start(_type, _args) do
      children = [
        {Incident,
         event_store: :in_memory,
         event_store_options: [],
         projection_store: :in_memory,
         projection_store_options: [
           initial_state: %{Bank.Projections.BankAccount => [], Bank.Projections.Transfer => []}
         ]}
      ]

      opts = [strategy: :one_for_one, name: Bank.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end
  ```
  """

  use ExUnit.Case

  alias Bank.{BankAccountCommandHandler, TransferCommandHandler}
  alias Bank.Commands.{DepositMoney, OpenAccount, RequestTransfer, WithdrawMoney}
  alias Bank.Projections.{BankAccount, Transfer}
  alias Ecto.UUID

  # This setup is only needed becasue we are testing InMemory adapter that uses Agent.
  # Diffrently than Ecto that uses a Sandbox to rollback changes from one test to another, with Agent,
  # the reset has to be manual.
  setup do
    Application.stop(:bank)
    :ok = Application.start(:bank)
  end

  @default_amount 100
  @account_number UUID.generate()
  @account_number2 UUID.generate()
  @command_open_account %OpenAccount{aggregate_id: @account_number}
  @command_deposit_money %DepositMoney{aggregate_id: @account_number, amount: @default_amount}
  @command_withdraw_money %WithdrawMoney{aggregate_id: @account_number, amount: @default_amount}

  describe "simple bank account operations" do
    test "successfully opening a bank account" do
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_open_account)

      assert [event] = Incident.EventStore.get(@account_number)

      assert event.aggregate_id == @account_number
      assert event.event_type == "AccountOpened"
      assert event.event_id
      assert event.event_date
      assert is_map(event.event_data)
      assert event.version == 1

      assert [bank_account] = Incident.ProjectionStore.all(BankAccount)

      assert bank_account.aggregate_id == @account_number
      assert bank_account.account_number == @account_number
      assert bank_account.balance == 0
      assert bank_account.version == 1
      assert bank_account.event_date
      assert bank_account.event_id
    end

    test "failing opening an account with same number more than once" do
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_open_account)

      assert {:error, :account_already_opened} = BankAccountCommandHandler.receive(@command_open_account)

      assert [event] = Incident.EventStore.get(@account_number)

      assert event.aggregate_id == @account_number
      assert event.event_type == "AccountOpened"
      assert event.event_id
      assert event.event_date
      assert is_map(event.event_data)
      assert event.version == 1

      assert [bank_account] = Incident.ProjectionStore.all(BankAccount)

      assert bank_account.aggregate_id == @account_number
      assert bank_account.account_number == @account_number
      assert bank_account.balance == 0
      assert bank_account.version == 1
      assert bank_account.event_date
      assert bank_account.event_id
    end

    test "depositing money into the account" do
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_open_account)
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_deposit_money)
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_deposit_money)

      assert [event1, event2, event3] = Incident.EventStore.get(@account_number)

      assert event1.aggregate_id == @account_number
      assert event1.event_type == "AccountOpened"
      assert event1.event_id
      assert event1.event_date
      assert is_map(event1.event_data)
      assert event1.version == 1

      assert event2.aggregate_id == @account_number
      assert event2.event_type == "MoneyDeposited"
      assert event2.event_id
      assert event2.event_date
      assert is_map(event2.event_data)
      assert event2.version == 2

      assert event3.aggregate_id == @account_number
      assert event3.event_type == "MoneyDeposited"
      assert event3.event_id
      assert event3.event_date
      assert is_map(event3.event_data)
      assert event3.version == 3

      assert [bank_account] = Incident.ProjectionStore.all(BankAccount)

      assert bank_account.aggregate_id == @account_number
      assert bank_account.account_number == @account_number
      assert bank_account.balance == @default_amount * 2
      assert bank_account.version == 3
      assert bank_account.event_date
      assert bank_account.event_id
    end

    test "failing on attempt to deposit money to a non-existing account" do
      assert {:error, :account_not_found} = BankAccountCommandHandler.receive(@command_deposit_money)
    end

    test "depositing and withdrawing money from account" do
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_open_account)
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_deposit_money)
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_withdraw_money)

      assert [event1, event2, event3] = Incident.EventStore.get(@account_number)

      assert event1.aggregate_id == @account_number
      assert event1.event_type == "AccountOpened"
      assert event1.event_id
      assert event1.event_date
      assert is_map(event1.event_data)
      assert event1.version == 1

      assert event2.aggregate_id == @account_number
      assert event2.event_type == "MoneyDeposited"
      assert event2.event_id
      assert event2.event_date
      assert is_map(event2.event_data)
      assert event2.version == 2

      assert event3.aggregate_id == @account_number
      assert event3.event_type == "MoneyWithdrawn"
      assert event3.event_id
      assert event3.event_date
      assert is_map(event3.event_data)
      assert event3.version == 3

      assert [bank_account] = Incident.ProjectionStore.all(BankAccount)

      assert bank_account.aggregate_id == @account_number
      assert bank_account.account_number == @account_number
      assert bank_account.balance == 0
      assert bank_account.version == 3
      assert bank_account.event_date
      assert bank_account.event_id
    end

    test "failing to withdraw more money than the account balance" do
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_open_account)

      assert {:error, :no_enough_balance} = BankAccountCommandHandler.receive(@command_withdraw_money)

      assert [event1] = Incident.EventStore.get(@account_number)

      assert event1.aggregate_id == @account_number
      assert event1.event_type == "AccountOpened"
      assert event1.event_id
      assert event1.event_date
      assert is_map(event1.event_data)
      assert event1.version == 1

      assert [bank_account] = Incident.ProjectionStore.all(BankAccount)

      assert bank_account.aggregate_id == @account_number
      assert bank_account.account_number == @account_number
      assert bank_account.balance == 0
      assert bank_account.version == 1
      assert bank_account.event_date
      assert bank_account.event_id
    end

    test "failing on attempt to withdraw money from a non-existing account" do
      assert {:error, :account_not_found} = BankAccountCommandHandler.receive(@command_withdraw_money)
    end
  end

  describe "transfering money from one account to another" do
    @transfer_id UUID.generate()
    @command_request_transfer %RequestTransfer{
      aggregate_id: @transfer_id,
      source_account_number: @account_number,
      destination_account_number: @account_number2,
      amount: @default_amount
    }

    setup do
      BankAccountCommandHandler.receive(@command_open_account)
      BankAccountCommandHandler.receive(@command_deposit_money)

      BankAccountCommandHandler.receive(%{
        @command_open_account
        | aggregate_id: @account_number2
      })

      :ok
    end

    test "transfer money from account to another when there is enough balance" do
      assert {:ok, _event} = TransferCommandHandler.receive(@command_request_transfer)

      assert [event1, event2, event3] = Incident.EventStore.get(@transfer_id)

      assert event1.aggregate_id == @transfer_id
      assert event1.event_type == "TransferRequested"
      assert event1.event_id
      assert event1.event_date
      assert is_map(event1.event_data)
      assert event1.version == 1

      assert [transfer] = Incident.ProjectionStore.all(Transfer)

      assert transfer.aggregate_id == @transfer_id
      assert transfer.source_account_number == @account_number
      assert transfer.destination_account_number == @account_number2
      assert transfer.amount == @default_amount
      assert transfer.status == "completed"
      assert transfer.version == 3
      assert transfer.event_date
      assert transfer.event_id

      bank_accounts = Incident.ProjectionStore.all(BankAccount)
      source_bank_account = Enum.find(bank_accounts, &(&1.aggregate_id == @account_number))
      destination_bank_account = Enum.find(bank_accounts, &(&1.aggregate_id == @account_number2))

      assert source_bank_account.balance == 0
      assert destination_bank_account.balance == @default_amount
    end

    test "does not transfer money when there is no enough balance" do
      over_amount = @default_amount + 1

      assert {:ok, _event} = TransferCommandHandler.receive(%{@command_request_transfer | amount: over_amount})

      assert [event1, event2] = Incident.EventStore.get(@transfer_id)

      assert event2.aggregate_id == @transfer_id
      assert event2.event_type == "TransferCancelled"
      assert event2.event_id
      assert event2.event_date
      assert is_map(event2.event_data)
      assert event2.version == 2

      assert [transfer] = Incident.ProjectionStore.all(Transfer)

      assert transfer.aggregate_id == @transfer_id
      assert transfer.source_account_number == @account_number
      assert transfer.destination_account_number == @account_number2
      assert transfer.amount == @default_amount + 1
      assert transfer.status == "cancelled"
      assert transfer.version == 2
      assert transfer.event_date
      assert transfer.event_id

      bank_accounts = Incident.ProjectionStore.all(BankAccount)
      source_bank_account = Enum.find(bank_accounts, &(&1.aggregate_id == @account_number))
      destination_bank_account = Enum.find(bank_accounts, &(&1.aggregate_id == @account_number2))
      assert source_bank_account.balance == @default_amount
      assert destination_bank_account.balance == 0
    end

    test "does not transfer money when source account does not exist" do
      unexisting_account = UUID.generate()

      assert {:ok, _event} =
               TransferCommandHandler.receive(%{
                 @command_request_transfer
                 | source_account_number: unexisting_account
               })

      assert [event1, event2] = Incident.EventStore.get(@transfer_id)

      assert event2.aggregate_id == @transfer_id
      assert event2.event_type == "TransferCancelled"
      assert event2.event_id
      assert event2.event_date
      assert is_map(event2.event_data)
      assert event2.version == 2

      assert [transfer] = Incident.ProjectionStore.all(Transfer)

      assert transfer.aggregate_id == @transfer_id
      assert transfer.source_account_number == unexisting_account
      assert transfer.destination_account_number == @account_number2
      assert transfer.amount == @default_amount
      assert transfer.status == "cancelled"
      assert transfer.version == 2
      assert transfer.event_date
      assert transfer.event_id

      bank_accounts = Incident.ProjectionStore.all(BankAccount)
      destination_bank_account = Enum.find(bank_accounts, &(&1.aggregate_id == @account_number2))
      assert destination_bank_account.balance == 0
    end

    test "does not transfer money when destination account does not exist" do
      unexisting_account = UUID.generate()

      assert {:ok, _event} =
               TransferCommandHandler.receive(%{
                 @command_request_transfer
                 | destination_account_number: unexisting_account
               })

      assert [event1, event2, event3, event4] = Incident.EventStore.get(@transfer_id)

      assert event4.aggregate_id == @transfer_id
      assert event4.event_type == "TransferCancelled"
      assert event4.event_id
      assert event4.event_date
      assert is_map(event4.event_data)
      assert event4.version == 4

      assert [transfer] = Incident.ProjectionStore.all(Transfer)

      assert transfer.aggregate_id == @transfer_id
      assert transfer.source_account_number == @account_number
      assert transfer.destination_account_number == unexisting_account
      assert transfer.amount == @default_amount
      assert transfer.status == "cancelled"
      assert transfer.version == 4
      assert transfer.event_date
      assert transfer.event_id

      bank_accounts = Incident.ProjectionStore.all(BankAccount)
      source_bank_account = Enum.find(bank_accounts, &(&1.aggregate_id == @account_number))
      assert source_bank_account.balance == @default_amount
    end
  end
end
