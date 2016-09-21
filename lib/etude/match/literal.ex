defmodule Etude.Match.Literal do
  defstruct [:value]

  defimpl Etude.Matchable do
    def compile(%{value: value}) do
      @for.compile(value)
    end

    def compile_body(%{value: value}) do
      @for.compile_body(value)
    end
  end

  def compile(l) do
    fn(v, _) ->
      Etude.Unifiable.unify(l, v)
    end
  end

  def compile_body(l) do
    fn(_) ->
      Etude.Future.of(l)
    end
  end
end

defimpl Etude.Matchable, for: [Atom, BitString, Float, Function, Integer, Pid, Port, Reference] do
  alias Etude.Match.Literal

  def compile(l) do
    Literal.compile(l)
  end

  def compile_body(l) do
    Literal.compile_body(l)
  end
end
