defmodule Etude.Match.Union do
  defstruct [:patterns]

  alias Etude.Match.Utils

  defimpl Etude.Matchable do
    def compile(%{patterns: patterns}) do
      patterns = Enum.map(patterns, &@protocol.compile/1)
      &Utils.exec_patterns(patterns, &1, &2, &3)
    end

    def compile_body(union) do
      compile(union)
    end
  end
end
