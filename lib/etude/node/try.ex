defmodule Etude.Node.Try do
  defstruct expression: nil,
            clauses: [],
            line: nil
end

defimpl Etude.Node, for: Etude.Node.Try do
  import Etude.Vars
  import Etude.Utils

  defdelegate assign(node, opts), to: Etude.Node.Any
  defdelegate call(node, opts), to: Etude.Node.Any
  defdelegate name(node, opts), to: Etude.Node.Any
  defdelegate pattern(node, opts), to: Etude.Node.Any
  defdelegate prop(node, opts), to: Etude.Node.Any
  defdelegate var(node, opts), to: Etude.Node.Any

  def compile(node, opts) do
    expression = [node.expression]
    children = Enum.map(node.clauses, fn({_, _, _, body}) ->
      body
    end)

    children = Enum.reduce(node.clauses, children, fn({_, pattern, _, _}, acc) ->
      Etude.Pattern.extract_vars(pattern, opts) ++ acc
    end)

    clauses = Enum.map(node.clauses, &(compile_clause(&1, node, opts))) |> Enum.join(";\n")

    defop node, opts, [:memoize], """
    try
      #{Etude.Node.call(expression, opts)}
    catch
    #{clauses}
    end
    """, Etude.Children.compile([expression | children], opts)
  end

  defp compile_clause({:error, pattern, guard, body}, _node, opts) do
    vars = Etude.Pattern.store_vars(pattern, opts)
    """
        error:{'__ETUDE_ERROR__', #{Etude.Node.pattern(pattern, opts)}, rebind(#{state})} #{compile_guard(guard, opts)} ->
          #{vars},
          #{Etude.Node.assign(body, [{:var, :local} | opts])},
          {#{Etude.Node.var(body, opts)}, #{state}};
        error:#{Etude.Node.pattern(pattern, opts)} #{compile_guard(guard, opts)} ->
          #{Etude.Node.assign(body, [{:var, :local} | opts])},
          {#{Etude.Node.var(body, opts)}, #{state}}
    """
  end
  defp compile_clause({type, pattern, guard, body}, _node, opts) do
    vars = Etude.Pattern.store_vars(pattern, opts)
    """
        #{type || "_"}:#{Etude.Node.pattern(pattern, opts)} #{compile_guard(guard, opts)} ->
          #{vars},
          #{Etude.Node.assign(body, [{:var, :local} | opts])},
          {#{Etude.Node.var(body, opts)}, #{state}}
    """
  end

  defp compile_guard(guard, _opts) when guard in [nil, []] do
    ""
  end
  defp compile_guard(_guard, _opts) do
    throw "Guard in case not implemented"
  end

  def children(node) do
    [node.expression,
      %Etude.Node.Block{
        side_effects: false,
        children: Enum.map(node.clauses, fn({type, pattern, guard, body}) ->
          %Etude.Node.Block{
            side_effects: false,
            children: [
              type,
              pattern,
              guard,
              body
            ]
          }
        end)
      }
    ]
  end

  def set_children(node, [expression, %{children: clauses}]) do
    clauses = for clause <- clauses do
      %{children: [type, pattern, guard, body]} = clause
      {type, pattern, guard, body}
    end
    %{node | expression: expression, clauses: clauses}
  end
end
