defmodule Bank.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Bank.EventStoreRepo,
      Bank.ProjectionStoreRepo,
      {Incident,
       event_store: :postgres,
       event_store_options: [
         repo: Bank.EventStoreRepo
       ],
       projection_store: :postgres,
       projection_store_options: [
         repo: Bank.ProjectionStoreRepo
       ]}
    ]

    opts = [strategy: :one_for_one, name: Bank.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
