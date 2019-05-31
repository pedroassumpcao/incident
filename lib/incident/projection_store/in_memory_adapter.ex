defmodule Incident.ProjectionStore.InMemoryAdapter do
  @moduledoc """
  Implements an in-memory Projection Store using Agents.
  """

  @behaviour Incident.ProjectionStore.Adapter

  use Agent

  @spec start_link(any) :: GenServer.on_start()
  def start_link(initial_state) do
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  @impl true
  # credo:disable-for-this-file
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
