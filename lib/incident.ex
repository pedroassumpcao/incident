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

defmodule Incident.Event.PersistedEvent do
  defstruct [:event_id, :aggregate_id, :event_type, :version, :event_date, :event_data]
end

# Projection

defmodule Incident.Projection.BankAccount do
  defstruct [:aggregate_id, :account_number, :version, :balance, :event_id, :event_date]
end

# Projection Store Adapter
defmodule Incident.ProjectionStore.Adapter do
  @callback project(:atom, map) :: map
  @callback all(:atom) :: list
end

defmodule Incident.ProjectionStore.InMemoryAdapter do
  @behaviour Incident.ProjectionStore.Adapter

  use Agent

  def start_link(initial_state) do
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  @impl true
  def project(projection_name, %{aggregate_id: aggregate_id} = data) do
    Agent.update(__MODULE__, fn state ->
      update_in(state, [projection_name], fn projections ->
        case Enum.find(projections, &(&1.aggregate_id == aggregate_id)) do
          nil ->
            [data] ++ projections

          _ ->
            Enum.reduce(projections, [], fn record, acc ->
              case record.aggregate_id == aggregate_id do
                true -> [Map.merge(record, data)] ++ acc
                false -> [record] ++ acc
              end
            end)
        end
      end)
    end)
  end

  @impl true
  def all(projection_name) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state, projection_name)
    end)
  end
end

# Projection Store
defmodule Incident.ProjectionStore do
  def project(projection_name, data) do
    apply(adapter(), :project, [projection_name, data])
  end

  def all(projection_name) do
    apply(adapter(), :all, [projection_name])
  end

  defp adapter do
    Incident.ProjectionStore.InMemoryAdapter
  end
end

# Event Handler
defmodule Incident.EventHandler do
  alias Incident.Event.PersistedEvent
  alias Incident.ProjectionStore
  alias Incident.Projection.BankAccount
  alias Incident.BankAccount, as: Aggregate

  def listen(%PersistedEvent{event_type: "AccountOpened"} = event, state) do
    new_state = Aggregate.apply(event, state)
    data = %BankAccount{
      aggregate_id: new_state.aggregate_id,
      account_number: new_state.account_number,
      balance: new_state.balance,
      version: event.version,
      event_id: event.event_id,
      event_date: event.event_date
    }
    ProjectionStore.project(:bank_accounts, data)
  end

  def listen(%PersistedEvent{event_type: "MoneyDeposited"} = event, state) do
    new_state = Aggregate.apply(event, state)
    data = %BankAccount{
      aggregate_id: new_state.aggregate_id,
      account_number: new_state.account_number,
      balance: new_state.balance,
      version: event.version,
      event_id: event.event_id,
      event_date: event.event_date
    }
    ProjectionStore.project(:bank_accounts, data)
  end
end

# Event Store Adapter
defmodule Incident.EventStore.Adapter do
  @callback get(String.t()) :: list
  @callback append(map) :: :ok
end

defmodule Incident.EventStore.InMemoryAdapter do
  @behaviour Incident.EventStore.Adapter

  use Agent

  alias Incident.Event.PersistedEvent

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  @impl true
  def get(aggregate_id) do
    __MODULE__
    |> Agent.get(& &1)
    |> Enum.filter(&(&1.aggregate_id == aggregate_id))
    |> Enum.reverse()
  end

  @impl true
  def append(event) do
    persisted_event = %PersistedEvent{
      event_id: :rand.uniform(100_000) |> Integer.to_string(),
      aggregate_id: event.aggregate_id,
      event_type: event.__struct__ |> Module.split() |> List.last(),
      version: event.version,
      event_date: DateTime.utc_now(),
      event_data: Map.from_struct(event)
    }

    Agent.update(__MODULE__, &([persisted_event] ++ &1))

    {:ok, persisted_event}
  end
end

# Event Store
defmodule Incident.EventStore do
  def get(aggregate_id) do
    apply(adapter(), :get, [aggregate_id])
  end

  def append(event) do
    apply(adapter(), :append, [event])
  end

  defp adapter do
    Incident.EventStore.InMemoryAdapter
  end
end

# Aggregate State
defmodule Incident.AggregateState do
  defmacro __using__(opts) do
    aggregate = Keyword.get(opts, :aggregate)
    initial_state = Keyword.get(opts, :initial_state)

    quote do
      import Incident.AggregateState

      alias Incident.EventStore

      def get(aggregate_id) do
        aggregate_id
        |> EventStore.get()
        |> Enum.reduce(unquote(initial_state), fn event, state ->
          unquote(aggregate).apply(event, state)
        end)
      end
    end
  end
end

defmodule Incident.BankAccountState do
  use Incident.AggregateState,
    aggregate: Incident.BankAccount,
    initial_state: %{
      aggregate_id: nil,
      account_number: nil,
      balance: nil,
      version: nil,
      updated_at: nil
    }
end

# Aggregate
defmodule Incident.Aggregate do
  @callback execute(struct) :: :ok | {:error, atom}
  @callback apply(struct, map) :: map
end

defmodule Incident.BankAccount do
  @behaviour Incident.Aggregate

  alias Incident.BankAccountState
  alias Incident.Command.{DepositMoney, OpenAccount}
  alias Incident.EventStore
  alias Incident.Event.{AccountOpened, MoneyDeposited}

  @impl true
  def execute(%OpenAccount{account_number: account_number}) do
    case BankAccountState.get(account_number) do
      %{account_number: nil} = state ->
        %AccountOpened{
          aggregate_id: account_number,
          account_number: account_number,
          version: 1
        }
        |> EventStore.append()
        |> case do
             {:ok, persisted_event} -> Incident.EventHandler.listen(persisted_event, state)
             error -> error
           end

      _ ->
        {:error, :account_already_opened}
    end
  end

  @impl true
  def execute(%DepositMoney{aggregate_id: aggregate_id, amount: amount}) do
    case BankAccountState.get(aggregate_id) do
      %{aggregate_id: aggregate_id} = state when not is_nil(aggregate_id) ->
        %MoneyDeposited{
          aggregate_id: aggregate_id,
          amount: amount,
          version: state.version + 1
        }
        |> EventStore.append()
        |> case do
             {:ok, persisted_event} -> Incident.EventHandler.listen(persisted_event, state)
             error -> error
           end


      _ ->
        {:error, :account_not_found}
    end
  end

  @impl true
  def apply(%{event_type: "AccountOpened"} = event, state) do
    %{
      state
      | aggregate_id: event.aggregate_id,
        account_number: event.event_data.account_number,
        balance: 0,
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(%{event_type: "MoneyDeposited"} = event, state) do
    %{
      state
      | balance: state.balance + event.event_data.amount,
        version: event.version,
        updated_at: event.event_date
    }
  end

  @impl true
  def apply(_, state) do
    state
  end
end
