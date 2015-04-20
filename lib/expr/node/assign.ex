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
      expression = node.expression

      quote do
        @compile {:nowarn_unused_function, {unquote(name), unquote(length(op_args))}}
        defp unquote(name)(unquote_splicing(op_args)) do
          Expr.Memoize.wrap unquote(name) do
            unquote(Expr.Node.assign(expression, opts))
            {unquote(Expr.Node.var(expression, opts)), unquote(state)}
          end
        end

        unquote(Expr.Node.compile(expression, opts))
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