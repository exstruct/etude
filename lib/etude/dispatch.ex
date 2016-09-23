defmodule Etude.Dispatch do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__.Helpers)
      @before_compile unquote(__MODULE__)

      def resolve(module, function, arity) do
        lookup(module, function, arity)
      end
      defoverridable resolve: 3

      rewrite :lists, Etude.STDLIB.Lists
    end
  end

  def from_process do
    Process.get(:__ETUDE_DISPATCH__, Etude.Dispatch.Fallback)
  end

  for arity <- 0..100 do
    args =
      case arity do
        0 ->
          []
        _ ->
          1..arity
          |> Enum.map(&Macro.var(:"arg_#{&1}", nil))
      end

    def __capture__(module, function, unquote(arity)) do
      fn(unquote_splicing(args)) ->
        call(module, function, unquote(args))
      end
    end
  end

  defp call(module, function, args) do
    args
    |> Enum.map(&Etude.Future.to_term(&1))
    |> Etude.Future.parallel()
    |> Etude.Future.chain(fn(args) ->
      Etude.Future.wrap(fn ->
        apply(module, function, args)
      end)
    end)
  end

  defmacro __before_compile__(_) do
    quote do
      defp lookup(module, function, arity) do
        future = function_exported?(module, :__etude__, 3) && module.__etude__(function, arity, __MODULE__)
        future || Etude.Future.of(unquote(__MODULE__).__capture__(module, function, arity))
      end
    end
  end
end
