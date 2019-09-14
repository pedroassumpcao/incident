defmodule Bank.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Bank.EventStoreRepo,
      Bank.ProjectionStoreRepo
    ]

    opts = [strategy: :one_for_one, name: Bank.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
