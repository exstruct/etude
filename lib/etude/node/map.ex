defimpl Etude.Node, for: Map do
  defdelegate assign(node, opts), to: Etude.Node.Any
  defdelegate call(node, opts), to: Etude.Node.Any
  defdelegate compile(node, opts), to: Etude.Node.Collection
  defdelegate name(node, opts), to: Etude.Node.Any
  defdelegate pattern(node, opts), to: Etude.Node.Collection
  defdelegate prop(node, opts), to: Etude.Node.Any
  defdelegate var(node, opts), to: Etude.Node.Any

  def children(node) do
    :maps.to_list(node)
  end

  def set_children(_, node) do
    :maps.from_list(node)
  end
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

  def match(_node, {key, value}, opts) do
    "#{Etude.Utils.escape(key)} := #{Etude.Node.pattern(value, opts)}"
  end

  def pattern(_node, matches) do
    "\#{#{matches}}"
  end
end
