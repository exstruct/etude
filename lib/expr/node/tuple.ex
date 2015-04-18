defimpl Expr.Node, for: Tuple do
  defdelegate compile(node, opts), to: Expr.Node.Collection
  defdelegate name(node, opts), to: Expr.Node.Any
  defdelegate call(node, context), to: Expr.Node.Any
  defdelegate assign(node, context), to: Expr.Node.Any
  defdelegate var(node, context), to: Expr.Node.Any
end

defimpl Expr.Node.Collection.Construction, for: Tuple do
  def construct(_node, vars) do
    quote do
      {unquote_splicing(vars)}
    end
  end
end