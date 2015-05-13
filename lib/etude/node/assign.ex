defmodule Etude.Node.Assign do
  defstruct name: nil,
            expression: nil,
            line: nil

  import Etude.Vars
  import Etude.Utils

  defimpl Etude.Node, for: Etude.Node.Assign do
    defdelegate assign(node, opts), to: Etude.Node.Any
    defdelegate call(node, opts), to: Etude.Node.Any
    defdelegate prop(node, opts), to: Etude.Node.Any
    defdelegate var(node, opts), to: Etude.Node.Any

    def compile(node, opts) do
      expression = node.expression

      defop node, opts, [:memoize, {:scope, Etude.Node.Assign.var_scope}], """
      #{Etude.Node.assign(expression, opts)},
      {#{Etude.Node.var(expression, opts)}, #{state}}
      """, Etude.Children.compile([expression], opts)
    end

    def children(node) do
      [node.expression]
    end

    def set_children(node, [expression]) do
      %{node | expression: expression}
    end

    def name(node, opts) do
      Etude.Node.Assign.resolve(node, opts)
    end
  end

  def var_scope do
    "element(1, #{scope})"
  end

  def assign(assign, name, opts) do
    v = Etude.Node.Assign.resolve(assign, opts)
    memo_put(v, "{#{ready}, #{name}}", var_scope)
  end

  def resolve(%Etude.Node.Assign{name: name}, opts) do
    resolve(name, opts)
  end
  def resolve(%Etude.Node.Var{name: name}, opts) do
    resolve(name, opts)
  end
  def resolve(nil, opts) do
    "#{opts[:main]}_var_nil" |> String.to_atom
  end
  def resolve(name, opts) when is_atom(name) do
    "#{opts[:main]}_var_#{name}"
    |> String.slice(0..254)
    |> String.to_atom
  end
end