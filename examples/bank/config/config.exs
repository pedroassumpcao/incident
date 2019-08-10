use Mix.Config

config :bank, ecto_repos: [Incident.EventStore.Ecto.Repo]

import_config "#{Mix.env()}.exs"
