defmodule Etude.Mixfile do
  use Mix.Project

  def project do
    [app: :etude,
     version: "1.0.0-beta.0",
     elixir: "~> 1.0",
     description: "parallel computation coordination utilities for erlang/elixir",
     deps: deps,
     package: package,
     aliases: aliases]
  end

  def application do
    [applications: [:logger]]
  end

  defp aliases do
    [bench: [&set_bench_env/1, "bench"]]
  end

  defp set_bench_env(_) do
    Mix.env(:bench)
  end

  defp deps do
    [{:nile, "~> 0.1.3"},
     {:poison, "~> 2.1.0"},
     {:excheck, "~> 0.2.3", only: [:dev, :test, :bench]},
     {:triq, github: "krestenkrab/triq", only: [:dev, :test, :bench]},
     {:benchfella, "~> 0.3.1", only: [:dev, :test, :bench]},
     {:mix_test_watch, "~> 0.2", only: :dev}]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     maintainers: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/camshaft/etude"}]
  end
end
