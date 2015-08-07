defmodule Etude.Pattern do
  alias Etude.Node

  def extract_vars(pattern, _opts \\ []) do
    recurse(%Node.Block{children: [pattern]}, [])
  end

  def store_vars(pattern, opts \\ []) do
    vars = extract_vars(pattern, opts)
    |> Enum.map(fn(var) ->
      v = Node.var(var, opts)
      Node.Assign.assign(var, v, opts)
    end)

    case vars do
      [] ->
        "nil"
      vars ->
        Enum.join(vars, ",\n      ")
    end
  end

  defp recurse(node, acc) do
    children_reduce(Node.children(node), acc)
  end

  def children_reduce(children, acc) when is_tuple(children) do
    children
    |> Tuple.to_list
    |> children_reduce(acc)
  end
  def children_reduce(children, acc) do
    Enum.reduce(children, acc, fn
      (%Node.Assign{} = child, acc) ->
        [child | recurse(child, acc)]
      (child, acc) ->
        recurse(child, acc)
    end)
  end
end
