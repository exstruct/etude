defmodule Etude.Mixfile do
  use Mix.Project

  def project do
    [app: :etude,
     version: "0.3.0",
     elixir: "~> 1.0",
     description: "parallel computation coordination compiler for erlang/elixir",
     deps: deps,
     test_coverage: [tool: ExCoveralls],
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
    [{:rebind, "~> 0.1.0"},
     {:lineo, "~> 0.1.0"},
     # hex doesn't publish github deps. i'd prefer uwiger publish parse_trans.
     # anyone that uses etude will need to add this manually for now
     {:parse_trans, github: "uwiger/parse_trans"},
     {:excheck, "~> 0.2.3", only: [:dev, :test, :bench]},
     {:triq, github: "krestenkrab/triq", only: [:dev, :test, :bench]},
     {:excoveralls, "~> 0.3", only: [:dev, :test]},
     {:benchfella, "~> 0.2.0", only: [:dev, :test, :bench]}]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     contributors: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/camshaft/etude"}]
  end
end
