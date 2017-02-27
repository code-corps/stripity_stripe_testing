defmodule FakeStripe.Mixfile do
  use Mix.Project

  def project do
    [
      app: :fake_stripe,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
     ]
  end

  def application do
    [
      mod: {FakeStripe.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ranch, "~> 1.2"},
      {:cowboy, "~> 1.0"},
      {:plug, "~> 1.2 or ~> 1.3"}
    ]
  end
end
