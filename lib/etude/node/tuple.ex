defimpl Etude.Node, for: Tuple do
  defdelegate compile(node, opts), to: Etude.Node.Collection
  defdelegate name(node, opts), to: Etude.Node.Any
  defdelegate call(node, context), to: Etude.Node.Any
  defdelegate assign(node, context), to: Etude.Node.Any
  defdelegate prop(node, opts), to: Etude.Node.Any
  defdelegate var(node, context), to: Etude.Node.Any
end

defimpl Etude.Node.Collection.Construction, for: Tuple do
  def construct(_node, vars) do
    "{#{vars}}"
  end
end