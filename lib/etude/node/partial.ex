defmodule Etude.Node.Partial do
  defstruct module: nil,
            function: nil,
            props: %{},
            line: nil

  alias Etude.Children
  import Etude.Vars
  import Etude.Utils

  defimpl Etude.Node, for: Etude.Node.Partial do
    defdelegate assign(node, opts), to: Etude.Node.Any
    defdelegate call(node, opts), to: Etude.Node.Any
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate pattern(node, opts), to: Etude.Node.Any
    defdelegate prop(node, opts), to: Etude.Node.Any
    defdelegate var(node, opts), to: Etude.Node.Any

    def children(node) do
      [node.module, node.function | :maps.to_list(node.props)]
    end

    def set_children(node, [module, function | props]) do
      %{node | module: module, function: function, props: :maps.from_list(props)}
    end

    def compile(%{module: module, function: function, props: props} = node, opts) when is_atom(module) and is_atom(function) do
      mod = escape(module)
      fun_a = "#{function}_partial" |> String.to_atom
      fun = escape(fun_a)
      scope = {module, function, props}

      defop node, opts, [:memoize], """
      _Props = #{Children.props(props, opts)},
      #{child_scope(scope)},
      #{debug_call(mod, fun, "[_Props]", opts)},
      #{mod}:#{fun}(#{op_args}, _Props)
      """, Children.compile(Map.values(props), opts)
    end
    def compile(%{module: module, function: function, props: props} = node, opts) do
      defop node, opts, [:memoize], """
      _Props = #{Children.props(props, opts)},
      #{Children.call([module, function], opts)},

      case {#{Children.vars([module, function], opts)}} of
        {{#{ready}, Mod}, {#{ready}, Func}} ->
          PartialFunc = binary_to_atom(iolist_to_binary([atom_to_binary(Func, utf8), <<"_partial">>]), utf8),
          #{child_scope(['Mod', 'PartialFunc', escape(props)])},
          #{debug_call('Mod', 'PartialFunc', '[_Props]', opts)},
          Mod:PartialFunc(#{op_args}, _Props);
        _ ->
          #{debug('<<"#{Etude.Node.name(node, opts)} deps pending">>', opts)},
          {nil, #{state}}
      end
      """, Children.compile([module, function | Map.values(props)], opts)
    end
  end
end
