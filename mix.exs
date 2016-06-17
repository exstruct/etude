defmodule Etude.Mixfile do
  use Mix.Project

  def project do
    [app: :etude,
     version: "0.4.1",
     elixir: "~> 1.0",
     description: "parallel computation coordination compiler for erlang/elixir",
     deps: deps,
     package: package,
     aliases: aliases,
     consolidate_protocols: !(Mix.env in [:test, :bench])]
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
    [{:rebind, "~> 0.1.3"},
     {:lineo, "~> 0.1.0"},
     {:parse_trans, "~> 2.9.0"},
     {:excheck, "~> 0.3.2", only: [:dev, :test, :bench]},
     {:triq, github: "krestenkrab/triq", only: [:dev, :test, :bench]},
     {:benchfella, "~> 0.3.1", only: [:dev, :test, :bench]}]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     maintainers: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/camshaft/etude"}]
  end
end
