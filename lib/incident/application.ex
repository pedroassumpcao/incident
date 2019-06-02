defmodule Incident.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {event_store_config()[:adapter], event_store_config()[:initial_state]},
      {projection_store_config()[:adapter], projection_store_config()[:initial_state]}
    ]

    opts = [strategy: :one_for_one, name: Incident.Supervisor]
    Supervisor.start_link(children, opts)
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
