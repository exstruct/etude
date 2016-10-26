defmodule Etude.Mixfile do
  use Mix.Project

  def project do
    [app: :etude,
     version: "1.0.0",
     elixir: "~> 1.0",
     description: "futures for elixir/erlang",
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [
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
    [{:excheck, "~> 0.4.1", only: [:dev, :test, :bench]},
     {:triq, github: "krestenkrab/triq", only: [:dev, :test, :bench]},
     {:eministat, github: "jlouis/eministat", only: [:dev, :test, :bench]},
     {:mix_test_watch, "~> 0.2", only: :dev},
     {:fugue, "~> 0.1", only: [:test, :bench]},
     {:excoveralls, "~> 0.5.1", only: [:test, :bench]},
     {:dialyxir, "~> 0.3.5", only: [:dev]},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     maintainers: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/exstruct/etude"}]
  end
end
