defmodule Incident.MixProject do
  use Mix.Project

  @github "https://github.com/pedroassumpcao/incident"

  def project do
    [
      app: :incident,
      version: "0.1.0",
      elixir: "~> 1.8",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [extras: ["README.md"]],
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

  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.20.2", only: :dev, runtime: false}
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

end
