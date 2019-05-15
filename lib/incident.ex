# Commands
defmodule Incident.Command.OpenAccount do
  defstruct [:account_number]
end

defmodule Incident.Command.DepositMoney do
  defstruct [:aggregate_id, :amount]
end

# Events
defmodule Incident.Event.AccountOpened do
  defstruct [:aggregate_id, :account_number, :version]
end

defmodule Incident.Event.MoneyDeposited do
  defstruct [:aggregate_id, :amount, :version]
end

# Event Store Adapter
defmodule Incident.Event.Store.Adapter do
  @callback get(String.t()) :: list
  @callback append(map) :: :ok
end

defmodule Incident.Event.Store.InMemoryAdapter do

  @behaviour Incident.Event.Store.Adapter

  use Agent

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  @impl true
  def get(aggregate_id) do
    __MODULE__
    |> Agent.get(&(&1))
    |> Enum.filter(&(&1.aggregate_id == aggregate_id))
    |> Enum.reverse()
  end

  @impl true
  def append(event) do
    persisted_event = %{
      aggregate_id: event.aggregate_id,
      event_type: event.__struct__ |> Module.split() |> List.last(),
      version: event.version,
      event_date: DateTime.utc_now(),
      event_data: Map.from_struct(event)
    }

    Agent.update(__MODULE__, &([persisted_event] ++ &1))
  end
end

# Event Store
defmodule Incident.Event.Store do

  def get(aggregate_id), do: adapter().get(aggregate_id)

  def append(event), do: adapter().append(event)

  defp adapter do
    Incident.Event.Store.InMemoryAdapter
  end
end

# Aggregate State
defmodule Incident.Aggregate.State do
  defstruct [:aggregate_id, :account_number, :balance, :version, :updated_at]

  alias Incident.Aggregate
  alias Incident.Event.Store

  def get(aggregate_id) do
    aggregate_id
    |> Store.get()
    |> Enum.reduce(%__MODULE__{}, fn event, state ->
      Aggregate.apply(event, state)
    end)
  end
end

# Aggregate
defmodule Incident.Aggregate do

  alias Incident.Aggregate.State
  alias Incident.Command.{DepositMoney, OpenAccount}
  alias Incident.Event.{AccountOpened, MoneyDeposited, Store}

  def execute(%OpenAccount{account_number: account_number}) do
    case State.get(account_number) do
      %State{account_number: nil} ->
        %AccountOpened{
          aggregate_id: account_number,
          account_number: account_number,
          version: 1
        }
        |> Store.append()

      _ -> {:error, :account_already_opened}
    end
  end

  def execute(%DepositMoney{aggregate_id: aggregate_id, amount: amount}) do
    case State.get(aggregate_id) do
      %State{aggregate_id: aggregate_id} = state when not is_nil(aggregate_id) ->
        %MoneyDeposited{
          aggregate_id: aggregate_id,
          amount: amount,
          version: state.version + 1
        }
        |> Store.append()

      _ -> {:error, :account_not_found}
    end
  end

  @spec apply(struct, struct) :: struct
  def apply(%{event_type: "AccountOpened"} = event, state) do
    %{state | aggregate_id: event.aggregate_id, account_number: event.event_data.account_number, balance: 0, version: event.version, updated_at: event.event_date}
  end

  def apply(%{event_type: "MoneyDeposited"} = event, state) do
    %{state | balance: state.balance + event.event_data.amount, version: event.version, updated_at: event.event_date}
  end

  def apply(_, state) do
    state
  end
end
