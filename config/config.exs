use Mix.Config

config :incident, ecto_repos: [Incident.EventStore.Ecto.Repo]

import_config "#{Mix.env()}.exs"
