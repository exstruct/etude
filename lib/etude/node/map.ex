defimpl Etude.Node, for: Map do
  defdelegate compile(node, opts), to: Etude.Node.Collection
  defdelegate name(node, opts), to: Etude.Node.Any
  defdelegate call(node, context), to: Etude.Node.Any
  defdelegate assign(node, context), to: Etude.Node.Any
  defdelegate var(node, context), to: Etude.Node.Any
end

defimpl Etude.Node.Collection.Construction, for: Map do
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
