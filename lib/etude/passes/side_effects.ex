defmodule Etude.Passes.SideEffects do
  alias Etude.Node

  def transform(ast, _opts \\ nil) do
    [%Node.Block{children: children}] = recurse([%Node.Block{children: ast}])
    children
  end

  defp recurse(node) do
    children = children_map(Node.children(node))
    Node.set_children(node, children)
  end

  def children_map(children) when is_tuple(children) do
    children
    |> Tuple.to_list
    |> children_map
    |> :erlang.list_to_tuple
  end
  def children_map(children) do
    Enum.map(children, fn
      (%Node.Block{side_effects: true} = child) ->
        %{child | children: inline(child.children, [], [])}
      (child) ->
        recurse(child)
    end)
  end

  defp inline([], assigns, _) do
    :lists.reverse(assigns)
  end
  defp inline([node], assigns, []) do
    inline([], [recurse(node) | assigns], [])
  end
  defp inline([node], assigns, se) do
    call = %Node.Call{
      module: :erlang,
      function: :hd,
      arguments: [[recurse(node) | :lists.reverse(se)]],
      attrs: %{
        native: true
      }
    }
    inline([], [call | assigns], [])
  end
  defp inline([%Node.Assign{} = node | rest], assigns, se) do
    inline(rest, [recurse(node) | assigns], se)
  end
  defp inline([node | rest], assigns, se) do
    inline(rest, assigns, [recurse(node) | se])
  end
end
