defmodule Expr.Memoize do
  import Expr.Vars

  defmacro get(key, opts \\ []) do
    scope = Keyword.get(opts, :scope, scope())
    quote do
      Process.get({unquote(req), unquote(scope), unquote(key)})
    end
  end

  defmacro put(key, value, opts \\ []) do
    scope = Keyword.get(opts, :scope, scope())
    quote do
      Process.put({unquote(req), unquote(scope), unquote(key)}, unquote(value))
    end
  end

  defmacro wrap(key, opts) do
    block = Keyword.get(opts, :do)

    quote do
      case Expr.Memoize.get(unquote(key)) do
        nil ->
          case unquote(block) do
            {nil, _} = res ->
              res
            {val, _} = res ->
              Expr.Memoize.put(unquote(key), val)
              res
          end
        val ->
          Logger.debug(fn -> unquote("#{inspect(key)} cached -> ") <> inspect(elem(val, 1)) <> " (scope #{unquote(scope)})" end)
          {val, unquote(state)}
      end
    end
  end
end