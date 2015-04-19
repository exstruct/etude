defmodule Expr.Node.Var do
  defstruct name: nil,
            line: 1 

  import Expr.Vars

  defimpl Expr.Node, for: Expr.Node.Var do
    defdelegate name(node, opts), to: Expr.Node.Any
    defdelegate call(node, context), to: Expr.Node.Any
    defdelegate assign(node, context), to: Expr.Node.Any
    defdelegate var(node, context), to: Expr.Node.Any

    def compile(node, opts) do
      name = Expr.Node.name(node, opts)

      quote do
        @compile {:nowarn_unused_function, {unquote(name), unquote(length(op_args))}}
        @compile {:inline, [{unquote(name), unquote(length(op_args))}]}
        defp unquote(name)(unquote_splicing(op_args)) do
          unquote(Expr.Node.Assign.resolve(node, opts))(unquote_splicing(op_args))
        end
      end
    end
  end
end