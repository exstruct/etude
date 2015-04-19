defmodule Expr.Node.Cond do
  defstruct expression: nil,
            arms: [],
            line: 1

  alias Expr.Children
  alias Expr.Utils
  import Expr.Vars

  def normalize(node = %{:arms => []}) do
    Map.put(node, :arms, [:undefined, :undefined])
  end
  def normalize(node = %{:arms => [arm1]}) do
    Map.put(node, :arms, [arm1, :undefined])
  end
  def normalize(node) do
    node
  end

  defimpl Expr.Node, for: Expr.Node.Cond do
    defdelegate call(node, opts), to: Expr.Node.Any
    defdelegate assign(node, opts), to: Expr.Node.Any
    defdelegate var(node, opts), to: Expr.Node.Any

    def name(node, opts) do
      Expr.Node.Cond.normalize(node)
      |> Expr.Node.Any.name(opts)
    end

    def compile(node, opts) do
      node = %{:arms => arms = [arm1, arm2]} = Expr.Node.Cond.normalize(node)
      name = Expr.Node.name(node, opts)
      expression = node.expression
      quote line: node.line do
        @compile {:inline, [{unquote(name), unquote(length(op_args))}]}
        defp unquote(name)(unquote_splicing(op_args)) do
          Expr.Memoize.wrap unquote(name) do
            ## condition
            unquote(Expr.Node.assign(expression, opts))

            # look at the condition value
            case unquote(Expr.Node.var(expression, opts)) do
              # falsy
              {unquote(Utils.ready), val} when val in [false, nil, :undefined] ->
                unquote(Expr.Node.assign(arm2, opts))
                {unquote(Expr.Node.var(arm2, opts)), unquote(state)}
              # truthy
              {unquote(Utils.ready), _} ->
                unquote(Expr.Node.assign(arm1, opts))
                {unquote(Expr.Node.var(arm1, opts)), unquote(state)}
              # not ready
              _ ->
                {nil, unquote(state)}
            end
          end
        end
        unquote_splicing(Children.compile([expression|arms], opts))
      end
    end
  end
end