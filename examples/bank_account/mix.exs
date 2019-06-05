defmodule BankAccount.MixProject do
  use Mix.Project

  def project do
    [
      app: :bank_account,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {BankAccount.Application, []}
    ]
  end

  defp deps do
    [
      {:incident, path: "../..", override: true}
    ]
  end
end
