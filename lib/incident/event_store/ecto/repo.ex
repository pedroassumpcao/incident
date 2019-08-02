defmodule Incident.EventStore.Ecto.Repo do
  use Ecto.Repo,
    otp_app: :incident,
    adapter: Ecto.Adapters.Postgres
end
