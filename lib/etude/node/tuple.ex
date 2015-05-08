defimpl Etude.Node, for: Tuple do
  defdelegate assign(node, opts), to: Etude.Node.Any
  defdelegate call(node, opts), to: Etude.Node.Any
  defdelegate compile(node, opts), to: Etude.Node.Collection
  defdelegate name(node, opts), to: Etude.Node.Any
  defdelegate prop(node, opts), to: Etude.Node.Any
  defdelegate var(node, opts), to: Etude.Node.Any

  def children(node) do
    Tuple.to_list(node)
  end

  def set_children(_, node) do
    List.to_tuple(node)
  end
end

defimpl Etude.Node.Collection.Construction, for: Tuple do
  def construct(_node, vars) do
    "{#{vars}}"
  end
end