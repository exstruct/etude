defmodule Etude.Node.Block do
  defstruct children: [],
            side_effects: true,
            line: nil

  defimpl Etude.Node, for: Etude.Node.Block do
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate prop(node, opts), to: Etude.Node.Any

    def assign(node, opts) do
      last(node) |> Etude.Node.assign(opts)
    end

    def call(node, opts) do
      last(node) |> Etude.Node.call(opts)
    end

    def children(node) do
      node.children || []
    end

    def set_children(node, children) do
      %{node | children: children}
    end

    def compile(node, opts) do
      Etude.Children.compile(node.children, opts)
    end

    def var(node, opts) do
      last(node) |> Etude.Node.var(opts)
    end

    defp last(node) do
      List.last(node.children)
    end
  end
end
