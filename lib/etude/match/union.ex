defmodule Etude.Match.Union do
  defstruct [:patterns]

  defimpl Etude.Matchable do
    alias Etude.Match.Executable

    def compile(%{patterns: patterns}) do
      p = patterns |> Enum.map(&@protocol.compile/1)
      %Executable{
        module: __MODULE__,
        env: p
      }
    end

    def __execute__(p, v, b) do
      p
      |> Enum.map(&Executable.execute(&1, v, b))
      |> Etude.Future.parallel()
      |> Etude.Future.map(fn([v | _]) -> v end)
    end

    def compile_body(%{patterns: patterns}) do
      p = patterns |> Enum.map(&@protocol.compile_body/1)
      %Executable{
        module: __MODULE__,
        function: :__execute_body__,
        env: p
      }
    end

    def __execute_body__(p, b) do
      p
      |> Enum.map(&Executable.execute(&1, b))
      |> Etude.Future.parallel()
      |> Etude.Future.map(fn([v | _]) -> v end)
    end
  end
end
