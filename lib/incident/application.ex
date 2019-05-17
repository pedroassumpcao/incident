defmodule Incident.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Incident.Event.Store.InMemoryAdapter, []},
      {Incident.Projection.Store.InMemoryAdapter, %{bank_accounts: []}}
    ]

    opts = [strategy: :one_for_one, name: Incident.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
