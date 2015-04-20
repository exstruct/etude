defmodule Etude.Node.Cond do
  defstruct expression: nil,
            arms: [],
            line: 1

  alias Etude.Children
  alias Etude.Utils
  import Etude.Vars

  def normalize(node = %{:arms => []}) do
    Map.put(node, :arms, [:undefined, :undefined])
  end
  def normalize(node = %{:arms => [arm1]}) do
    Map.put(node, :arms, [arm1, :undefined])
  end
  def normalize(node) do
    node
  end

  defimpl Etude.Node, for: Etude.Node.Cond do
    defdelegate call(node, opts), to: Etude.Node.Any
    defdelegate assign(node, opts), to: Etude.Node.Any
    defdelegate var(node, opts), to: Etude.Node.Any

    def name(node, opts) do
      Etude.Node.Cond.normalize(node)
      |> Etude.Node.Any.name(opts)
    end

    def compile(node, opts) do
      node = %{:arms => arms = [arm1, arm2]} = Etude.Node.Cond.normalize(node)
      name = Etude.Node.name(node, opts)
      expression = node.expression
      quote line: node.line do
        @compile {:nowarn_unused_function, {unquote(name), unquote(length(op_args))}}
        @compile {:inline, [{unquote(name), unquote(length(op_args))}]}
        defp unquote(name)(unquote_splicing(op_args)) do
          Etude.Memoize.wrap unquote(name) do
            ## condition
            unquote(Etude.Node.assign(expression, opts))

            # look at the condition value
            case unquote(Etude.Node.var(expression, opts)) do
              # falsy
              {unquote(Utils.ready), val} when val in [false, nil, :undefined] ->
                unquote(Etude.Node.assign(arm2, opts))
                {unquote(Etude.Node.var(arm2, opts)), unquote(state)}
              # truthy
              {unquote(Utils.ready), _} ->
                unquote(Etude.Node.assign(arm1, opts))
                {unquote(Etude.Node.var(arm1, opts)), unquote(state)}
              # not ready
              _ ->
                {nil, unquote(state)}
            end
          end
        end
        unquote_splicing(Children.compile([expression|arms], opts))
      end
    end
  end
end