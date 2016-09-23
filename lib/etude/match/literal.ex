defmodule Etude.Match.Literal do
  alias Etude.Match.Executable
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
    %Executable{
      module: __MODULE__,
      env: l
    }
  end

  def __execute__(l, v, _) do
    Etude.Unifiable.unify(l, v)
  end

  def compile_body(l) do
    %Executable{
      module: __MODULE__,
      function: :__execute_body__,
      env: l
    }
  end

  def __execute_body__(l, _) do
    Etude.Future.of(l)
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
