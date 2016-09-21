defmodule Etude.Match.Scope do
  defstruct [:fun]
end

defimpl Etude.Matchable, for: Etude.Match.Scope do
  require Etude.Future

  def compile(p) do
    throw {:invalid_pattern, p}
  end

  def compile_body(%{fun: fun}) do
    fn(b) ->
      Etude.Future.new(fn(state, rej, res) ->
        state
        |> Etude.Match.Utils.fetch_bindings(b)
        |> fun.()
        |> Etude.Forkable.fork(state, rej, res)
      end)
    end
  end
end
