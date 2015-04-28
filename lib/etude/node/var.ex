defmodule Etude.Node.Var do
  defstruct name: nil,
            line: nil

  import Etude.Vars
  import Etude.Utils

  defimpl Etude.Node, for: Etude.Node.Var do
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate call(node, context), to: Etude.Node.Any
    defdelegate assign(node, context), to: Etude.Node.Any
    defdelegate prop(node, opts), to: Etude.Node.Any
    defdelegate var(node, context), to: Etude.Node.Any

    def compile(node, opts) do
      name = Etude.Node.name(node, opts)
      target = Etude.Node.Assign.resolve(node, opts)

      defop node, opts, [:inline], """
      ?DEBUG(<<"#{name} resolving var from #{target}">>),
      #{target}(#{op_args})
      """
    end
  end
end