defmodule Etude.Dispatch.Helpers do
  defmacro rewrite({:&, _, [source]}, target) do
    quote do
      rewrite(unquote(source), unquote(target))
    end
  end
  defmacro rewrite(source, {:&, _, target}) do
    quote do
      rewrite(unquote(source), unquote(target))
    end
  end
  defmacro rewrite({:/, _, [{{:., _, [source_module, source_function]}, _, _}, arity]},
                   {:/, _, [{{:., _, [target_module, target_function]}, _, _}, arity]}) do
    quote do
      defp lookup(unquote(source_module), unquote(source_function), unquote(arity)) do
        lookup(unquote(target_module), unquote(target_function), unquote(arity))
      end
    end
  end
  defmacro rewrite(source_module, target_module) do
    quote do
      defp lookup(unquote(source_module), function, arity) do
        lookup(unquote(target_module), function, arity)
      end
    end
  end
end
