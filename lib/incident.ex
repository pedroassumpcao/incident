defmodule Incident do
  @moduledoc false

  use Supervisor

  @doc """
  Starts an instance of Incident by the Incident supervisor.
  """
  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [], name: Incident.Supervisor)
  end

  @impl true
  def init(_config) do
    children = [
      {event_store_adapter(), event_store_options()},
      {projection_store_adapter(), projection_store_options()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec event_store_adapter :: module | no_return
  defp event_store_adapter do
    event_store_config()[:adapter] || raise "An Event Store adapter is required in the config."
  end

  @spec event_store_options :: keyword
  defp event_store_options do
    event_store_config()[:options] || []
  end

  @spec projection_store_adapter :: module | no_return
  defp projection_store_adapter do
    projection_store_config()[:adapter] ||
      raise "A Projection Store adapter is required in the config."
  end

  @spec projection_store_options :: keyword
  defp projection_store_options do
    projection_store_config()[:options] || []
  end

  @spec event_store_config :: keyword
  defp event_store_config do
    Application.get_env(:incident, :event_store)
  end

  @spec projection_store_config :: keyword
  defp projection_store_config do
    Application.get_env(:incident, :projection_store)
  end
end
