defmodule Etude.Node.Literal do
  defstruct line: 1,
            value: nil

  defimpl Etude.Node, for: Etude.Node.Literal do
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate var(node, context), to: Etude.Node.Any

    def compile(_literal, _opts) do
      []
    end

    def call(node, _) do
      Macro.escape({Etude.Utils.ready, node.value})
    end

    def assign(node, context) do
      quote do
        unquote(Etude.Node.var(node)) = unquote(Etude.Node.call(node, context))
      end
    end
  end
end