defmodule Incident.MixProject do
  use Mix.Project

  @github "https://github.com/pedroassumpcao/incident"

  def project do
    [
      app: :incident,
      version: "0.6.2",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        all_tests: :test
      ],
      docs: [extras: ["README.md"]],
      aliases: aliases(),
      package: package(),
      source_url: @github,
      homepage_url: @github,
      description: "Event Sourcing and CQRS building blocks."
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.2"},
      {:ecto_sql, "~> 3.9"},
      {:ex_doc, "~> 0.21", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.11", only: :test},
      {:jason, "~> 1.0"},
      {:postgrex, ">= 0.0.0"}
    ]
  end

  defp package do
    [
      name: "incident",
      maintainers: ["Pedro Assumpcao"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github}
    ]
  end

  defp aliases do
    [
      all_tests: [
        "compile --force --warnings-as-errors",
        "credo --strict",
        "format --check-formatted",
        "coveralls",
        "dialyzer"
      ],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp dialyzer do
    [
      ignore_warnings: ".dialyzer_ignore.exs",
      plt_add_apps: [:eex, :ex_unit, :mix]
    ]
  end
end
