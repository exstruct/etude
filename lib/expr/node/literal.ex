defmodule Expr.Node.Literal do
  defstruct line: 1,
            value: nil

  defimpl Expr.Node, for: Expr.Node.Literal do
    defdelegate name(node, opts), to: Expr.Node.Any
    defdelegate var(node, context), to: Expr.Node.Any

    def compile(_literal, _opts) do
      []
    end

    def call(node, _) do
      Macro.escape({Expr.Utils.ready, node.value})
    end

    def assign(node, context) do
      quote do
        unquote(Expr.Node.var(node)) = unquote(Expr.Node.call(node, context))
      end
    end
  end
end