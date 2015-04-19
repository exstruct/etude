defmodule Expr.Node.Assign do
  defstruct name: nil,
            expression: nil,
            line: 1 

  import Expr.Vars

  defimpl Expr.Node, for: Expr.Node.Assign do
    defdelegate call(node, opts), to: Expr.Node.Any
    defdelegate assign(node, opts), to: Expr.Node.Any
    defdelegate var(node, opts), to: Expr.Node.Any

    def name(node, opts) do
      Expr.Node.Assign.resolve(node, opts)
    end

    def compile(node, opts) do
      name = Expr.Node.name(node, opts)

      quote do
        defp unquote(name)(unquote_splicing(op_args)) do
          Expr.Memoize.wrap unquote(name) do
            unquote(Expr.Node.assign(node.expression, opts))
            {unquote(Expr.Node.var(node.expression, opts)), unquote(state)}
          end
        end
      end
    end
  end

  def resolve(%Expr.Node.Assign{name: name}, opts) do
    resolve(name, opts)
  end
  def resolve(%Expr.Node.Var{name: name}, opts) do
    resolve(name, opts)
  end
  def resolve(name, opts) when is_atom(name) do
    prefix = Keyword.get(opts, :prefix)
    "#{prefix}_var_#{name}" |> String.to_atom
  end
end