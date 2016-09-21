defmodule Etude.Match.Union do
  defstruct [:patterns]

  defimpl Etude.Matchable do
    def compile(%{patterns: patterns}) do
      p = patterns |> Enum.map(&@protocol.compile/1)
      fn(v, b) ->
        p
        |> Enum.map(&(&1.(v, b)))
        |> Etude.Future.parallel()
        |> Etude.Future.map(fn([v | _]) -> v end)
      end
    end

    def compile_body(%{patterns: patterns}) do
      p = patterns |> Enum.map(&@protocol.compile_body/1)
      fn(b) ->
        p
        |> Enum.map(&(&1.(b)))
        |> Etude.Future.parallel()
        |> Etude.Future.map(fn([v | _]) -> v end)
      end
    end
  end
end
