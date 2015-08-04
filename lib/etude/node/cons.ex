defmodule Etude.Node.Cons do
  defstruct children: [],
            expression: [],
            line: nil
end

defimpl Etude.Node, for: Etude.Node.Cons do
  defdelegate assign(node, opts), to: Etude.Node.Any
  defdelegate call(node, opts), to: Etude.Node.Any
  defdelegate compile(node, opts), to: Etude.Node.Collection
  defdelegate name(node, opts), to: Etude.Node.Any
  defdelegate pattern(node, opts), to: Etude.Node.Collection
  defdelegate prop(node, opts), to: Etude.Node.Any
  defdelegate var(node, opts), to: Etude.Node.Any

  def children(node) do
    {node.expression, node.children}
  end

  def set_children(node, {expression, children}) do
    %{node | children: children, expression: expression}
  end
end

defimpl Etude.Node.Collection.Construction, for: Etude.Node.Cons do
  def construct(_node, vars) do
    [expression | rest] = String.split(vars, ", ")
    "[#{Enum.join(rest, ", ")} | #{expression}]"
  end

  def match(_node, value, opts) do
    Etude.Node.pattern(value, opts)
  end

  def pattern(_node, values) do
    [expression | rest] = String.split(values, ", ")
    "[#{Enum.join(rest, ", ")} | #{expression}]"
  end
end

defimpl Enumerable, for: Etude.Node.Cons do
  def count(cons) do
    {:ok, length(cons.children) + 1}
  end

  def member?(_cons, _value) do
    {:ok, false}
  end

  def reduce(cons, acc, fun) do
    Enumerable.reduce([cons.expression | cons.children], acc, fun)
  end
end
