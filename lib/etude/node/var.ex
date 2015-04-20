defmodule Etude.Node.Var do
  defstruct name: nil,
            line: 1 

  import Etude.Vars

  defimpl Etude.Node, for: Etude.Node.Var do
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate call(node, context), to: Etude.Node.Any
    defdelegate assign(node, context), to: Etude.Node.Any
    defdelegate var(node, context), to: Etude.Node.Any

    def compile(node, opts) do
      name = Etude.Node.name(node, opts)
      target = Etude.Node.Assign.resolve(node, opts)

      quote do
        @compile {:nowarn_unused_function, {unquote(name), unquote(length(op_args))}}
        @compile {:inline, [{unquote(name), unquote(length(op_args))}]}
        defp unquote(name)(unquote_splicing(op_args)) do
          Logger.debug(unquote("#{name} resolving var from #{target}"))
          unquote(target)(unquote_splicing(op_args))
        end
      end
    end
  end
end