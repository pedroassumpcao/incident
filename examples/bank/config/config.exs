use Mix.Config

config :bank, ecto_repos: [Bank.EventStoreRepo]

import_config "#{Mix.env()}.exs"
