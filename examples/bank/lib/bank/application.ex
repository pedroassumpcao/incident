defmodule Bank.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    config = %{
      event_store: %{
        adapter: :postgres,
        options: [repo: Bank.EventStoreRepo]
      },
      projection_store: %{
        adapter: :postgres,
        options: [repo: Bank.ProjectionStoreRepo]
      }
    }

    children = [
      Bank.EventStoreRepo,
      Bank.ProjectionStoreRepo,
      {Incident, config}
    ]

    opts = [strategy: :one_for_one, name: Bank.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
