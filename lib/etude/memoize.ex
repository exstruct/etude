defmodule Etude.Memoize do
  import Etude.Vars

  defmacro get(key, opts \\ []) do
    scope = Keyword.get(opts, :scope, scope())
    quote do
      :erlang.get({unquote(req), unquote(scope), unquote(key)})
    end
  end

  defmacro put(key, value, opts \\ []) do
    scope = Keyword.get(opts, :scope, scope())
    quote do
      :erlang.put({unquote(req), unquote(scope), unquote(key)}, unquote(value))
    end
  end

  defmacro wrap(key, opts) do
    block = Keyword.get(opts, :do)

    quote do
      case Etude.Memoize.get(unquote(key)) do
        :undefined ->
          case unquote(block) do
            {nil, _} = res ->
              res
            {val, _} = res ->
              Etude.Memoize.put(unquote(key), val)
              res
          end
        val ->
          Logger.debug(fn -> unquote("#{inspect(key)} cached -> ") <> inspect(elem(val, 1)) <> " (scope #{unquote(scope)})" end)
          {val, unquote(state)}
      end
    end
  end
end