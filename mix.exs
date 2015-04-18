defmodule Expr.Mixfile do
  use Mix.Project

  def project do
    [app: :expr,
     version: "1.0.0",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end
end
