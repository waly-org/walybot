defmodule Walybot.Mixfile do
  use Mix.Project

  def project do
    [app: :walybot,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {Walybot.Application, []}]
  end

  defp deps do
    [
      {:appsignal, "~> 1.0"},
      {:cowboy, "~> 1.1"},
      {:ecto, "~> 2.1"},
      {:httpoison, "~> 0.11.2"},
      {:poison, "~> 3.0"},
      {:postgrex, "~> 0.13"},
      {:plug, "~> 1.3"},
    ]
  end
end
