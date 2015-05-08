defmodule Etude.Node.Partial do
  defstruct module: nil,
            function: nil,
            props: %{},
            line: 1

  alias Etude.Children
  import Etude.Vars
  import Etude.Utils

  defimpl Etude.Node, for: Etude.Node.Partial do
    defdelegate assign(node, opts), to: Etude.Node.Any
    defdelegate call(node, opts), to: Etude.Node.Any
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate prop(node, opts), to: Etude.Node.Any
    defdelegate var(node, opts), to: Etude.Node.Any

    def children(node) do
      :maps.to_list(node.props)
    end

    def set_children(node, props) do
      %{node | props: :maps.from_list(props)}
    end

    def compile(node, opts) do
      mod = escape(node.module)
      fun_a = "#{node.function}_partial" |> String.to_atom
      fun = escape(fun_a)
      props = node.props
      scope = :erlang.phash2({mod, fun, props})

      defop node, opts, [:memoize], """
      _Props = #{Children.props(props, opts)},
      #{child_scope(scope)},
      #{debug_call(node.module, fun_a, "[_Props]", opts)},
      #{mod}:#{fun}(#{op_args}, _Props)
      """, Children.compile(Map.values(props), opts)
    end
  end
end