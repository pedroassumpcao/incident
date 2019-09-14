defmodule Incident.EventStore.TestRepo do
  @moduledoc false
  use Ecto.Repo, otp_app: :incident, adapter: Ecto.Adapters.Postgres
end
