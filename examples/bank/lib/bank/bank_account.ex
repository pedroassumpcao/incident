defmodule Bank.BankAccount do
  @behaviour Incident.Aggregate

  alias Bank.BankAccountState

  alias Bank.Commands.{
    DepositMoney,
    OpenAccount,
    ReceiveMoney,
    RevertMoneySent,
    SendMoney,
    WithdrawMoney
  }

  alias Bank.Events.{
    AccountOpened,
    MoneyDeposited,
    MoneyReceived,
    MoneySent,
    MoneySentReverted,
    MoneyWithdrawn
  }

  @impl true
  def execute(%OpenAccount{aggregate_id: account_number}) do
    case BankAccountState.get(account_number) do
      %{account_number: nil} = state ->
        new_event = %AccountOpened{
          aggregate_id: account_number,
          account_number: account_number,
          version: 1
        }

        {:ok, new_event, state}

      _state ->
        {:error, :account_already_opened}
    end
  end

  @impl true
  def execute(%DepositMoney{aggregate_id: aggregate_id, amount: amount}) do
    case BankAccountState.get(aggregate_id) do
      %{aggregate_id: aggregate_id} = state when not is_nil(aggregate_id) ->
        new_event = %MoneyDeposited{
          aggregate_id: aggregate_id,
          amount: amount,
          version: state.version + 1
        }

        {:ok, new_event, state}

      %{aggregate_id: nil} ->
        {:error, :account_not_found}
    end
  end

  @impl true
  def execute(%WithdrawMoney{aggregate_id: aggregate_id, amount: amount}) do
    with %{aggregate_id: aggregate_id} = state when not is_nil(aggregate_id) <-
           BankAccountState.get(aggregate_id),
         true <- state.balance >= amount do
      new_event = %MoneyWithdrawn{
        aggregate_id: aggregate_id,
        amount: amount,
        version: state.version + 1
      }

      {:ok, new_event, state}
    else
      %{aggregate_id: nil} -> {:error, :account_not_found}
      false -> {:error, :no_enough_balance}
    end
  end

  @impl true
  def execute(%SendMoney{aggregate_id: aggregate_id, amount: amount} = command) do
    with %{aggregate_id: aggregate_id} = state when not is_nil(aggregate_id) <-
           BankAccountState.get(aggregate_id),
         true <- state.balance >= amount do
      new_event = %MoneySent{
        aggregate_id: aggregate_id,
        transfer_id: command.transfer_id,
        amount: amount,
        version: state.version + 1
      }

      {:ok, new_event, state}
    else
      %{aggregate_id: nil} -> {:error, :account_not_found}
      false -> {:error, :no_enough_balance}
    end
  end

  @impl true
  def execute(%ReceiveMoney{aggregate_id: aggregate_id, amount: amount} = command) do
    case BankAccountState.get(aggregate_id) do
      %{aggregate_id: aggregate_id} = state when not is_nil(aggregate_id) ->
        new_event = %MoneyReceived{
          aggregate_id: aggregate_id,
          transfer_id: command.transfer_id,
          amount: amount,
          version: state.version + 1
        }

        {:ok, new_event, state}

      %{aggregate_id: nil} ->
        {:error, :account_not_found}
    end
  end

  @impl true
  def execute(%RevertMoneySent{aggregate_id: aggregate_id, amount: amount} = command) do
    case BankAccountState.get(aggregate_id) do
      %{aggregate_id: aggregate_id} = state when not is_nil(aggregate_id) ->
        new_event = %MoneySentReverted{
          aggregate_id: aggregate_id,
          transfer_id: command.transfer_id,
          amount: amount,
          version: state.version + 1
        }

        {:ok, new_event, state}

      %{aggregate_id: nil} ->
        {:error, :account_not_found}
    end
  end

  @impl true
  def apply(%{event_type: "AccountOpened"} = event, state) do
    %{
      state
      | aggregate_id: event.aggregate_id,
        account_number: event.event_data["account_number"],
        balance: 0,
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(%{event_type: "MoneyDeposited"} = event, state) do
    %{
      state
      | balance: state.balance + event.event_data["amount"],
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(%{event_type: "MoneyWithdrawn"} = event, state) do
    %{
      state
      | balance: state.balance - event.event_data["amount"],
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(%{event_type: "MoneySent"} = event, state) do
    %{
      state
      | balance: state.balance - event.event_data["amount"],
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(%{event_type: "MoneySentReverted"} = event, state) do
    %{
      state
      | balance: state.balance + event.event_data["amount"],
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(%{event_type: "MoneyReceived"} = event, state) do
    %{
      state
      | balance: state.balance + event.event_data["amount"],
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(_, state) do
    state
  end
end
