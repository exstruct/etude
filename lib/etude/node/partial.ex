defmodule Etude.Node.Partial do
  defstruct module: {:__MODULE__, [], nil},
            function: nil,
            arguments: [],
            line: 1

  alias Etude.Children
  import Etude.Vars

  defimpl Etude.Node, for: Etude.Node.Partial do
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate call(node, context), to: Etude.Node.Any
    defdelegate assign(node, context), to: Etude.Node.Any
    defdelegate var(node, context), to: Etude.Node.Any

    def compile(node, opts) do
      name = Etude.Node.name(node, opts)
      mod = node.module
      fun = "#{node.function}_partial" |> String.to_atom
      exec = "#{name}_exec" |> String.to_atom
      children = node.arguments

      quote line: node.line do
        @compile {:nowarn_unused_function, {unquote(name), unquote(length(op_args))}}
        @compile {:inline, [{unquote(name), unquote(length(op_args))}]}
        defp unquote(name)(unquote_splicing(op_args)) do
          Etude.Memoize.wrap unquote(name) do
            ## dependencies
            unquote_splicing(Children.call(children, opts))

            ## exec
            case unquote(mod).unquote(fun)(unquote_splicing(op_args), unquote(Children.vars(children, opts))) do
              nil ->
                Logger.debug(unquote("#{name} partial_pending"))
                {nil, unquote(state)}
              {val, state} ->
                Logger.debug(fn -> unquote("#{name} partial result -> ") <> inspect(elem(val, 1)) end)
                {val, state}
            end
          end
        end

        @compile {:inline, [{unquote(exec), unquote(length(children) + length(op_args))}]}
        defp unquote(exec)(unquote_splicing(Children.args(children, opts)), unquote_splicing(op_args)) do
          args = unquote(Children.vars(children, opts))
          ## create a new scope
          unquote(child_scope(:args, __MODULE__))
          Logger.debug(fn ->
            unquote("#{name} partial ") <> to_string(unquote(mod)) <> unquote(".#{fun}(") <>
              (Enum.map(args, &inspect/1) |> Enum.join(", ")) <> ")"
          end)
          case unquote(mod).unquote(fun)(unquote_splicing(op_args), args) do
            nil ->
              Logger.debug(unquote("#{name} partial_pending"))
              {nil, unquote(state)}
            {val, state} ->
              Logger.debug(fn -> unquote("#{name} partial result -> ") <> inspect(elem(val, 1)) end)
              {val, state}
          end
        end
        defp unquote(exec)(unquote_splicing(Children.wildcard(children, opts)), unquote_splicing(op_args)) do
          {nil, unquote(state)}
        end
      end
    end
  end
end