defmodule Etude.Passes.Scopes do
  defmodule Scope do
    defstruct id: nil,
              vars: %{},
              phase: :scan

    def put(%{vars: vars, phase: :scan, id: id} = scope, %{name: name} = node, opts) do
      case Dict.get(vars, name) do
        ^id ->
          IO.puts("#{opts[:file]}:#{node.line} Warning: variable '#{format_name(name)}' is being reassigned")
        nil ->
          nil
        _ ->
          IO.puts("#{opts[:file]}:#{node.line} Warning: variable '#{format_name(name)}' is being shadowed")
      end
      %{scope | vars: Dict.put(vars, name, scope.id)}
    end
    def put(scope, _node, _opts) do
      scope
    end

    def reset(scope = %{vars: vars1}, %{vars: vars2, id: id}) do
      %{scope | vars: Dict.merge(vars1, vars2), id: id, phase: :scan}
    end

    defp format_name(nil), do: "nil"
    defp format_name(name), do: name
  end

  alias Etude.Node

  def transform(ast, opts) do
    {block, _} = visit(%Node.Block{children: ast}, %Scope{phase: :update}, opts)
    block.children
  end

  defp visit(%Node.Assign{} = node, scope, opts) do
    scope = Scope.put(scope, node, opts)
    node = update_name(node, scope, opts)
    recurse(node, scope, opts)
  end
  defp visit(%Node.Block{} = node, %Scope{phase: :scan} = scope, _opts) do
    {node, scope}
  end
  defp visit(%Node.Block{} = node, scope, opts) do
    id = :erlang.phash2([scope.id, node])
    {node, child_scope} = recurse(node, %{scope | id: id, phase: :scan}, opts)
    {node, _} = recurse(node, %{child_scope | phase: :update}, opts)
    {node, scope}
  end
  defp visit(%Node.Var{} = node, scope, opts) do
    {update_name(node, scope, opts), scope}
  end
  defp visit(node, scope, opts) do
    recurse(node, scope, opts)
  end

  defp recurse(node, scope, opts) do
    {children, scope} = map_reduce_children(Node.children(node), scope, opts)
    {Node.set_children(node, children), scope}
  end

  def map_reduce_children(children, scope, opts) when is_tuple(children) do
    {children, scope} = map_reduce_children(Tuple.to_list(children), scope, opts)
    {:erlang.list_to_tuple(children), scope}
  end
  def map_reduce_children(children, scope, opts) do
    Enum.map_reduce(children, scope, &(visit(&1, &2, opts)))
  end

  defp update_name(node, %{phase: :scan}, _opts) do
    node
  end
  defp update_name(%{name: name, line: line} = node, %{vars: vars}, opts) do
    case Dict.get(vars, name) do
      nil ->
        raise CompileError, description: "undefined variable '#{name}'", line: line, file: Keyword.get(opts, :file, "")
      id ->
        %{node | name: format_name([name, id])}
    end
  end

  defp format_name(info) do
    info |> :erlang.phash2 |> to_string |> String.to_atom
  end
end
