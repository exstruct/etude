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
    defdelegate prop(node, opts), to: Etude.Node.Any
    defdelegate var(node, opts), to: Etude.Node.Any

    def compile(node, opts) do
      expression = [node.expression]
      name = Etude.Node.name(node, opts)
      exec = "#{name}_exec" |> String.to_atom

      defop node, opts, [:memoize], """
      #{Children.call(expression, opts)},
      case #{exec}(#{Children.vars(expression, opts, ", ")}#{op_args}) of
        nil ->
          {nil, #{state}};
        Res ->
          Res
      end
      """, Dict.put(Etude.Children.compile([expression], opts), exec, compile_exec(exec, node, opts))
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

    def compile_clause({_whens, _pattern, _body}, _node, _opts) do
      """
          %% TODO
          _ -> {{#{ready}, 'TODO'}, #{state}}
      """
    end

    def children(node) do
      [node.expression]
    end

    def set_children(node, [expression]) do
      %{node | expression: expression}
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
