defmodule Etude.Node.Cond do
  defstruct expression: nil,
            arms: [],
            line: nil

  alias Etude.Children
  import Etude.Utils
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
    defdelegate assign(node, opts), to: Etude.Node.Any
    defdelegate call(node, opts), to: Etude.Node.Any
    defdelegate prop(node, opts), to: Etude.Node.Any
    defdelegate var(node, opts), to: Etude.Node.Any

    def children(node) do
      [node.expression | node.arms]
    end

    def set_children(node, [expression | arms]) do
      %{node | expression: expression, arms: arms}
    end

    def compile(node, opts) do
      node = %{:arms => arms = [arm1, arm2]} = Etude.Node.Cond.normalize(node)
      expression = node.expression

      defop node, opts, [:memoize], """
      %% condition
      #{Etude.Children.call([expression], opts)},

      %% look at the condition value
      case #{Etude.Children.vars([expression], opts)} of
        % falsy
        {#{ready}, Val} when Val =:= false orelse Val =:= nil orelse Val =:= undefined ->
          #{Etude.Children.call([arm2], opts)},
          {#{Etude.Children.vars([arm2], opts)}, #{state}};
        % truthy
        {#{ready}, _} ->
          #{Etude.Children.call([arm1], opts)},
          {#{Etude.Children.vars([arm1], opts)}, #{state}};
        % not ready
        _ ->
          {nil, #{state}}
      end
      """, Children.compile([expression|arms], opts)
    end

    def name(node, opts) do
      Etude.Node.Cond.normalize(node)
      |> Etude.Node.Any.name(opts)
    end
  end
end