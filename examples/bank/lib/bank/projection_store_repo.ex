defmodule Bank.ProjectionStoreRepo do
  use Ecto.Repo,
    otp_app: :bank,
    adapter: Ecto.Adapters.Postgres
end
