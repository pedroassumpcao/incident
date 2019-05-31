defmodule Incident.MixProject do
  use Mix.Project

  @github "https://github.com/pedroassumpcao/incident"

  def project do
    [
      app: :incident,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
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
      description: "Event Sourcing and CQRS abstractions."
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Incident.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.20.2", only: :dev, runtime: false},
      {:excoveralls, "~> 0.11.1", only: :test}
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
        "dialyzer --halt-exit-status"
      ]
    ]
  end
end
