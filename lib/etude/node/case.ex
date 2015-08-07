defmodule Etude.Node.Case do
  defstruct clauses: [],
            expression: nil,
            line: nil

  alias Etude.Children
  import Etude.Vars
  import Etude.Utils

  defimpl Etude.Node, for: Etude.Node.Case do
    defdelegate assign(node, opts), to: Etude.Node.Any
    defdelegate call(node, opts), to: Etude.Node.Any
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate pattern(node, opts), to: Etude.Node.Any
    defdelegate prop(node, opts), to: Etude.Node.Any
    defdelegate var(node, opts), to: Etude.Node.Any

    def compile(node, opts) do
      expression = [node.expression]
      name = Etude.Node.name(node, opts)
      exec = "#{name}_exec" |> String.to_atom

      children = Enum.map(node.clauses, fn({_, _, body}) ->
        body
      end)

      children = Enum.reduce(node.clauses, children, fn({pattern, _, _}, acc) ->
        Etude.Pattern.extract_vars(pattern, opts) ++ acc
      end)

      defop node, opts, [:memoize], """
      #{Children.call(expression, opts)},
      case #{exec}(#{Children.vars(expression, opts, ", ")}#{op_args}) of
        nil ->
          {nil, #{state}};
        Res ->
          Res
      end
      """, Dict.put(Etude.Children.compile([expression | children], opts), exec, compile_exec(exec, node, opts))
    end

    defp compile_exec(name, node, opts) do
      expression = [node.expression]
      clauses = Enum.map(node.clauses, &(compile_clause(&1, node, opts))) |> Enum.join(";\n")
      """
      #{file_line(node, opts)}
      #{name}(#{Children.args(expression, opts, ", ")}#{op_args}) ->
        case #{Children.vars(expression, opts)} of
      #{clauses}
        end;
      #{name}(#{Children.wildcard(expression, opts, ", ")}#{op_args}) ->
        nil.
      """
    end

    defp compile_clause({pattern, guard, body}, _node, opts) do
      """
          #{Etude.Node.pattern(pattern, opts)} #{compile_guard(guard, opts)} ->
            #{Etude.Pattern.store_vars(pattern, opts)},
            #{Etude.Node.assign(body, opts)},
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
          children: Enum.map(node.clauses, fn({pattern, guard, body}) ->
            %Etude.Node.Block{
              side_effects: false,
              children: [
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
        %{children: [pattern, guard, body]} = clause
        {pattern, guard, body}
      end
      %{node | expression: expression, clauses: clauses}
    end
  end
end

defimpl Inspect, for: Etude.Node.Case do
  def inspect(node, _) do
    """
    case #{inspect(node.expression)} do
      # TODO
    end
    """
  end
end
