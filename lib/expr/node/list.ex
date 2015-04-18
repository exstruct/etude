defimpl Expr.Node, for: List do
  defdelegate compile(node, opts), to: Expr.Node.Collection
  defdelegate name(node, opts), to: Expr.Node.Any
  defdelegate call(node, context), to: Expr.Node.Any
  defdelegate assign(node, context), to: Expr.Node.Any
  defdelegate var(node, context), to: Expr.Node.Any
end

defimpl Expr.Node.Collection.Construction, for: List do
  def construct(_node, vars) do
    vars
  end
end