defmodule BankTest do
  use ExUnit.Case

  alias Bank.BankAccountCommandHandler
  alias Bank.Commands.{DepositMoney, OpenAccount}
  alias Bank.Projections.BankAccount
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
    assert :ok = BankAccountCommandHandler.receive(@command_open_account)

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

  test "invalid commands don't generate new events" do
    assert :ok = BankAccountCommandHandler.receive(@command_open_account)

    assert {:error, :account_already_opened} =
             BankAccountCommandHandler.receive(@command_open_account)

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

  test "executes an open account and deposit money commands" do
    assert :ok = BankAccountCommandHandler.receive(@command_open_account)
    assert :ok = BankAccountCommandHandler.receive(@command_deposit_money)
    assert :ok = BankAccountCommandHandler.receive(@command_deposit_money)

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
    assert bank_account.balance == 200
    assert bank_account.version == 3
    assert bank_account.event_date
    assert bank_account.event_id
  end
end
