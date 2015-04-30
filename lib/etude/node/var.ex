defmodule Etude.Node.Var do
  defstruct name: nil,
            line: nil

  import Etude.Vars

  defimpl Etude.Node, for: Etude.Node.Var do
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate assign(node, context), to: Etude.Node.Any
    defdelegate prop(node, opts), to: Etude.Node.Any
    defdelegate var(node, context), to: Etude.Node.Any

    def compile(_node, _opts) do
      nil
    end

    def call(node, opts) do
      target = Etude.Node.Assign.resolve(node, opts)
      "#{target}(#{op_args})"
    end
  end
end