defmodule Etude.Node.Assign do
  defstruct name: nil,
            expression: nil,
            line: 1 

  import Etude.Vars

  defimpl Etude.Node, for: Etude.Node.Assign do
    defdelegate call(node, opts), to: Etude.Node.Any
    defdelegate assign(node, opts), to: Etude.Node.Any
    defdelegate var(node, opts), to: Etude.Node.Any

    def name(node, opts) do
      Etude.Node.Assign.resolve(node, opts)
    end

    def compile(node, opts) do
      name = Etude.Node.name(node, opts)
      expression = node.expression

      quote do
        @compile {:nowarn_unused_function, {unquote(name), unquote(length(op_args))}}
        defp unquote(name)(unquote_splicing(op_args)) do
          Etude.Memoize.wrap unquote(name) do
            Logger.debug(unquote("#{name} assigned from #{Etude.Node.name(expression, opts)}"))
            unquote(Etude.Node.assign(expression, opts))
            {unquote(Etude.Node.var(expression, opts)), unquote(state)}
          end
        end

        unquote(Etude.Node.compile(expression, opts))
      end
    end
  end

  def resolve(%Etude.Node.Assign{name: name}, opts) do
    resolve(name, opts)
  end
  def resolve(%Etude.Node.Var{name: name}, opts) do
    resolve(name, opts)
  end
  def resolve(nil, opts) do
    prefix = Keyword.get(opts, :prefix)
    "#{prefix}_var_nil" |> String.to_atom
  end
  def resolve(name, opts) when is_atom(name) do
    prefix = Keyword.get(opts, :prefix)
    "#{prefix}_var_#{name}" |> String.to_atom
  end
end