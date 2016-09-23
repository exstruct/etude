defmodule Etude.Match.Scope do
  defstruct [:fun]
end

defimpl Etude.Matchable, for: Etude.Match.Scope do
  alias Etude.Match.Executable
  require Etude.Future

  def compile(p) do
    throw {:invalid_pattern, p}
  end

  def compile_body(%{fun: nil}) do
    %Executable{
      module: __MODULE__,
      function: :__execute_scope__
    }
  end
  def compile_body(%{fun: fun}) do
    %Executable{
      module: __MODULE__,
      env: fun
    }
  end

  def __execute_scope__(_, b) do
    Etude.Future.new(fn(state, _rej, res) ->
      bindings = Etude.Match.Utils.fetch_bindings(state, b)
      res.(state, bindings)
    end)
  end

  def __execute__(fun, b) do
    Etude.Future.new(fn(state, rej, res) ->
      state
      |> Etude.Match.Utils.fetch_bindings(b)
      |> fun.()
      |> Etude.Forkable.fork(state, rej, res)
    end)
  end
end
