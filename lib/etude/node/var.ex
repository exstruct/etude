defmodule Etude.Node.Var do
  defstruct name: nil,
            line: nil

  import Etude.Vars

  defimpl Etude.Node, for: Etude.Node.Var do
    defdelegate assign(node, opts), to: Etude.Node.Any
    defdelegate children(node), to: Etude.Node.Any
    defdelegate set_children(node, children), to: Etude.Node.Any
    defdelegate compile(node, opts), to: Etude.Node.Any
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate prop(node, opts), to: Etude.Node.Any
    defdelegate var(node, opts), to: Etude.Node.Any

    def call(node, opts) do
      target = Etude.Node.Assign.resolve(node, opts)
      "#{target}(#{op_args})"
    end
  end
end

defimpl Inspect, for: Etude.Node.Var do
  def inspect(node, _) do
    "#Var<#{node.name}>"
  end
end