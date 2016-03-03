defmodule Etude.Dispatch.EagerApplication do
  defstruct module: nil,
            function: nil,
            arguments: [],
            arity: 0

  def new(module, function, arity) do
    %__MODULE__{module: module,
                function: function,
                arity: arity,
                arguments: arguments_for_arity(arity)}
  end

  args = fn
    (0) ->
      []
    (arity) ->
      for _ <- 1..arity do
        nil
      end
  end

  for arity <- 0..48 do
    args = args.(arity)

    defp arguments_for_arity(unquote(arity)) do
      unquote(args)
    end
  end
end

defimpl Etude.Thunk, for: Etude.Dispatch.EagerApplication do
  def resolve(%{module: module, function: function, arguments: arguments, arity: arity}, state) when length(arguments) == arity do
    Etude.Thunk.resolve_all(arguments, state, fn(arguments, state) ->
      Etude.Cache.memoize(state, {module, function, arguments}, fn() ->
        apply(module, function, arguments)
      end)
    end)
  end
end
