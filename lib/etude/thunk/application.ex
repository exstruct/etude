defmodule Etude.Thunk.Application do
  defstruct function: nil,
            arguments: [],
            arity: 0,
            evaluation: :lazy

  def new(function, arity, evaluation \\ :lazy)
  def new(function, arguments, evaluation) when is_list(arguments) do
    %__MODULE__{function: function,
                arity: length(arguments),
                arguments: arguments,
                evaluation: evaluation}
  end
  def new(function, arity, evaluation) when is_integer(arity) do
    %__MODULE__{function: function,
                arity: arity,
                arguments: Etude.Thunk.RemoteApplication.__arguments__(arity),
                evaluation: evaluation}
  end
end

defimpl Etude.Thunk, for: Etude.Thunk.Application do
  def resolve(%{function: function, arguments: arguments, evaluation: :lazy}, state) do
    Etude.Cache.memoize(state, {function, arguments}, fn ->
      apply(function, arguments)
    end)
  end
  def resolve(%{function: function, arguments: arguments, evaluation: :shallow}, state) do
    Etude.Thunk.resolve_all(arguments, state, fn(arguments, state) ->
      Etude.Cache.memoize(state, {function, arguments}, fn() ->
        apply(function, arguments)
      end)
    end)
  end
  def resolve(%{function: _function, arguments: _arguments, evaluation: :eager}, _state) do
    :TODO
  end
end
