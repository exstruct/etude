defimpl Etude.Node, for: Map do
  defdelegate compile(node, opts), to: Etude.Node.Collection
  defdelegate name(node, opts), to: Etude.Node.Any
  defdelegate call(node, context), to: Etude.Node.Any
  defdelegate assign(node, context), to: Etude.Node.Any
  defdelegate prop(node, opts), to: Etude.Node.Any
  defdelegate var(node, context), to: Etude.Node.Any
end

defimpl Etude.Node.Collection.Construction, for: Map do
  def construct(_node, vars) do
    """
    lists:foldl(fun
      ({undefined, _}, Acc) ->
        Acc;
      ({_, undefined}, Acc) ->
        Acc;
      ({Key, Value}, Acc) ->
        maps:put(Key, Value, Acc)
    end, \#{}, [#{vars}])
    """
  end
end
