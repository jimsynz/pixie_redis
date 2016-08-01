defmodule Pixie.Redis.Mixfile do
  use Mix.Project

  def project do
    [
      app: :pixie_redis,
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      package: package,
      description: description
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :poolboy, :exredis],
     mod: {Pixie.Redis, []}]
  end

  defp package do
    [
      maintainers: ["James Harton"],
      licenses: ["MIT"],
      links: %{
        "messagerocket" => "https://messagerocket.co",
        "github"        => "https://github.com/messagerocket/pixie_redis"
      }
    ]
  end

  defp description do
    """
    Redis storage backend for Pixie, Elixir's Bayeux server.
    """
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:u_token,      "~> 0.0.2"},
      {:poolboy,      "~> 1.5"},
      {:ex_minimatch, "~> 0.0.1"},
      {:exredis,      "~> 0.2"},
      {:dogma,        "~> 0.1.7", only: :dev},
      {:ex_doc,       ">= 0.0.0", only: :dev}
    ]
  end
end
