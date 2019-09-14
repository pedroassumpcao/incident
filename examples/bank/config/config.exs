use Mix.Config

config :bank, ecto_repos: [Bank.EventStoreRepo, Bank.ProjectionStoreRepo]

import_config "#{Mix.env()}.exs"
