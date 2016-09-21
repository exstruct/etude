defmodule Etude.Dispatch do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__.Helpers)
      @before_compile unquote(__MODULE__)

      def resolve(module, function, arity) do
        lookup(module, function, arity)
      end
      defoverridable resolve: 3
    end
  end

  def from_process do
    Process.get(:__ETUDE_DISPATCH__, Etude.Dispatch.Fallback)
  end

  defmacro __before_compile__(_) do
    quote do
      defp lookup(module, function, arity) do
        future = function_exported?(module, :__etude__, 3) && module.__etude__(function, arity, __MODULE__)
        future || Etude.Future.of(fn(args) ->
          apply(module, function, args)
        end)
      end
    end
  end
end
