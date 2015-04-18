defimpl Expr.Node, for: Map do
  defdelegate compile(node, opts), to: Expr.Node.Collection
  defdelegate name(node, opts), to: Expr.Node.Any
  defdelegate call(node, context), to: Expr.Node.Any
  defdelegate assign(node, context), to: Expr.Node.Any
  defdelegate var(node, context), to: Expr.Node.Any
end

defimpl Expr.Node.Collection.Construction, for: Map do
  def construct(_node, vars) do
    quote do
      Enum.reduce([unquote_splicing(vars)], %{}, fn
        ({:undefined, _}, acc) ->
          acc
        ({_, :undefined}, acc) ->
          acc
        ({key, value}, acc) ->
          Map.put(acc, key, value)
      end)
    end
  end
end
