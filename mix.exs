defmodule Vector.MixProject do
  use Mix.Project

  @version "0.3.4"

  def project do
    [
      app: :vector_agent,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: dialyzer(),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      name: "Vector",
      docs: docs(),
      aliases: aliases(),
      preferred_cli_env: preferred_cli_env(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :erlexec]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(_), do: ["lib"]

  defp dialyzer do
    [
      plt_file: {:no_warn, "dialyzer/dialyzer.plt"},
      plt_add_apps: [:ex_unit, :mix]
    ]
  end

  defp description do
    """
    A library to embed Vector agents inside Elixir applications.
    """
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_url: "https://github.com/coherentpath/vector_agent",
      authors: ["Nicholas Sweeting"]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Nicholas Sweeting"],
      links: %{"GitHub" => "https://github.com/coherentpath/vector_agent"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  defp aliases do
    [
      setup: [
        "local.hex --if-missing --force",
        "local.rebar --if-missing --force",
        "deps.get"
      ],
      ci: [
        "setup",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "test",
        "dialyzer --format github",
        "sobelow --config"
      ]
    ]
  end

  # Specifies the preferred env for mix commands.
  defp preferred_cli_env do
    [
      ci: :test
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:erlexec, "~> 2.0"},
      {:telemetry, "~> 1.2"},
      {:jason, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.30.8", only: :dev, runtime: false},
      {:credo, "~> 1.7.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.1", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13.0", only: [:dev, :test], runtime: false}
    ]
  end
end
