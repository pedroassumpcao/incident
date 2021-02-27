defmodule Incident.ProjectionStore.InMemory.Adapter do
  @moduledoc """
  Implements an in-memory Projection Store using Agents.
  """

  @behaviour Incident.ProjectionStore.Adapter

  use Agent

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts \\ []) do
    initial_state = Keyword.get(opts, :initial_state, %{})

    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  @impl true
  # credo:disable-for-this-file
  def project(projection, %{aggregate_id: aggregate_id} = data) do
    Agent.update(__MODULE__, fn state ->
      update_in(state, [projection], fn projections ->
        case Enum.find(projections, &(&1.aggregate_id == aggregate_id)) do
          nil ->
            [struct(projection, data)] ++ projections

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

    {:ok, data}
  end

  @impl true
  def all(projection) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state, projection)
    end)
  end

  @impl true
  def get(projection, aggregate_id) do
    projection
    |> all()
    |> Enum.find(&(&1.aggregate_id == aggregate_id))
  end
end
