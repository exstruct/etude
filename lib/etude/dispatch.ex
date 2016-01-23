defmodule Etude.Dispatch do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [rewrite: 2]
      @before_compile unquote(__MODULE__)

      def resolve(module, function, arity) do
        lookup(module, function, arity)
      end
      defoverridable resolve: 3

      # defmacro call([do: block]) do
      #   quote do
      #     Process.put(:__ETUDE_DISPATCH__, unquote(__MODULE__))
      #     res = unquote(block)
      #     Process.delete(:__ETUDE_DISPATCH__)
      #     res
      #   end
      # end
      # defoverridable call: 1
    end
  end

  def from_process do
    Process.get(:__ETUDE_DISPATCH__, Etude.Dispatch.Fallback)
  end

  defmacro rewrite(source_module, target_module) do
    quote do
      defp lookup(unquote(source_module), function, arity) do
        lookup(unquote(target_module), function, arity)
      end
    end
  end

  defmacro __before_compile__(_) do
    quote do
      defp lookup(module, function, arity) do
        thunk = function_exported?(module, :__etude__, 3) && module.__etude__(function, arity, __MODULE__)
        thunk || Etude.Dispatch.eager_apply(module, function, arity)
      end
    end
  end

  args = fn
    (0) ->
      []
    (arity) ->
      for arg <- 1..arity do
        Macro.var(:"arg_#{arg}", nil)
      end
  end

  for arity <- 0..48 do
    args = args.(arity)

    def eager_apply(module, function, unquote(arity)) do
      %Etude.Thunk.Continuation{
        function: fn(arguments, state) ->
          Etude.Thunk.resolve_all(arguments, state, fn(arguments = unquote(args), state) ->
            Etude.State.memoize(state, {module, function, arguments}, fn() ->
              apply(module, function, unquote(args))
            end)
          end)
        end,
        arguments: unquote(args |> Enum.map(fn(_) -> nil end))
      }
    end
  end
end
