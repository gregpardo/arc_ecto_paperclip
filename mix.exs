defmodule Arc.Ecto.Paperclip.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :arc_ecto_paperclip,
     version: @version,
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps(),

    # Hex
     description: description(),
     package: package()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :arc]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp description do
    """
    An integration with Arc and Ecto that mimics paperclip capabilities.
    """
  end

  defp package do
    [maintainers: ["Greg Pardo"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/gregpardo/arc_ecto_paperclip"},
     files: ~w(mix.exs README.md lib)]
  end

  defp deps do
    [
      {:arc,  "~> 0.11.0"},
      {:arc_ecto, "~> 0.11.0"},
      {:ecto, ">= 2.1.0"},
      {:inflex, "~> 2.0"},
      {:httpoison, "~> 1.5"},
      {:mime, "~> 1.3"},
      {:mock, "~> 0.3", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
