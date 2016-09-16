defmodule Etude.Mixfile do
  use Mix.Project

  def project do
    [app: :etude,
     version: "1.0.0-beta.2",
     elixir: "~> 1.0",
     description: "parallel computation coordination utilities for erlang/elixir",
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [
       "bench": :bench,
       "coveralls": :test,
       "coveralls.circle": :test,
       "coveralls.detail": :test,
       "coveralls.html": :test
     ],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:nile, "~> 0.1.3"},
     {:poison, "~> 2.2.0"},
     {:excheck, "~> 0.4.1", only: [:dev, :test, :bench]},
     {:triq, github: "krestenkrab/triq", only: [:dev, :test, :bench]},
     {:benchfella, "~> 0.3.1", only: [:dev, :test, :bench]},
     {:mix_test_watch, "~> 0.2", only: :dev},
     {:fugue, "~> 0.1", only: [:test]},
     {:excoveralls, "~> 0.5.1", only: :test},]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     maintainers: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/camshaft/etude"}]
  end
end
