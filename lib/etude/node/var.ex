defmodule Etude.Node.Var do
  defstruct name: nil,
            line: nil

  import Etude.Vars
  import Etude.Utils

  defimpl Etude.Node, for: Etude.Node.Var do
    defdelegate children(node), to: Etude.Node.Any
    defdelegate set_children(node, children), to: Etude.Node.Any
    defdelegate compile(node, opts), to: Etude.Node.Any
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate prop(node, opts), to: Etude.Node.Any
    defdelegate var(node, opts), to: Etude.Node.Any

    def assign(node, opts) do
      var = Etude.Node.var(node, opts)
      if opts[:var] == :local do
        target = Etude.Node.Assign.resolve(node, opts)
        "#{var} = {#{ready}, _val_#{target}}"
      else
        "{#{var}, rebind(#{state})} = #{Etude.Node.call(node, opts)}"
      end
    end

    def call(node, opts) do
      target = Etude.Node.Assign.resolve(node, opts)
      "#{target}(#{op_args})"
    end

    def pattern(_node, _opts) do
      throw "Variable matching is not implemented yet"
    end
  end
end

defmodule Etude.Node.Var.Wildcard do
  defstruct line: nil
end

defimpl Etude.Node, for: Etude.Node.Var.Wildcard do
  defdelegate children(node), to: Etude.Node.Any
  defdelegate set_children(node, children), to: Etude.Node.Any

  for name <- [:assign, :call, :compile, :name, :prop, :var] do
    def unquote(name)(_, _) do
      throw "#{unquote(name)} is not supported for wildcard variables"
    end
  end

  def pattern(_node, _opts) do
    "_"
  end
end

defimpl Inspect, for: Etude.Node.Var do
  def inspect(node, _) do
    "#Var<#{node.name}>"
  end
end
