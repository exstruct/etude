defimpl Etude.Node, for: List do
  defdelegate assign(node, opts), to: Etude.Node.Any
  defdelegate call(node, opts), to: Etude.Node.Any
  defdelegate compile(node, opts), to: Etude.Node.Collection
  defdelegate name(node, opts), to: Etude.Node.Any
  defdelegate pattern(node, opts), to: Etude.Node.Collection
  defdelegate prop(node, opts), to: Etude.Node.Any
  defdelegate var(node, opts), to: Etude.Node.Any

  def children(node) do
    node
  end

  def set_children(_, node) do
    node
  end
end

defimpl Etude.Node.Collection.Construction, for: List do
  def construct(_node, vars) do
    "[#{vars}]"
  end

  def match(_node, value, opts) do
    Etude.Node.pattern(value, opts)
  end

  def pattern(_node, values) do
    "[#{values}]"
  end
end
