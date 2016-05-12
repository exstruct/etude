defmodule Etude.Thunk.RemoteApplication do
  defstruct module: nil,
            function: nil,
            arguments: [],
            arity: 0,
            evaluation: :lazy

  def new(module, function, arity, evaluation \\ :lazy)
  def new(module, function, arguments, evaluation) when is_list(arguments) do
    %__MODULE__{module: module,
                function: function,
                arity: length(arguments),
                arguments: arguments,
                evaluation: evaluation}
  end
  def new(module, function, arity, evaluation) when is_integer(arity) do
    %__MODULE__{module: module,
                function: function,
                arity: arity,
                arguments: __arguments__(arity),
                evaluation: evaluation}
  end

  args = fn
    (0) ->
      []
    (arity) ->
      for _ <- 1..arity do
        nil
      end
  end

  for arity <- 0..100 do
    args = args.(arity)

    def __arguments__(unquote(arity)) do
      unquote(args)
    end
  end
end

defimpl Etude.Thunk, for: Etude.Thunk.RemoteApplication do
  def resolve(%{module: module, function: function, arguments: arguments, evaluation: :lazy}, state) do
    Etude.Cache.memoize(state, {module, function, arguments}, fn ->
      apply(module, function, arguments)
    end)
  end
  def resolve(%{module: module, function: function, arguments: arguments, evaluation: :shallow}, state) do
    Etude.Thunk.resolve_all(arguments, state, fn(arguments, state) ->
      Etude.Cache.memoize(state, {module, function, arguments}, fn() ->
        apply(module, function, arguments)
      end)
    end)
  end
  def resolve(%{module: module, function: function, arguments: arguments, evaluation: :eager}, state) do
    Etude.Thunk.resolve_recursive({module, function, arguments}, state, fn(mfa = {module, function, arguments}, state) ->
      Etude.Cache.memoize(state, mfa, fn ->
        apply(module, function, arguments)
      end)
    end)
  end
end
