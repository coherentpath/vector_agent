defmodule Vector.MixProject do
  use Mix.Project

  def project do
    [
      app: :vector_agent,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :erlexec]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:erlexec, "~> 2.0"},
      {:telemetry, "~> 1.2"}
    ]
  end
end
