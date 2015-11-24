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
      IO.inspect [props: :maps.to_list(node.props), function: node.function, module: node.module, where: :children]
      [props: :maps.to_list(node.props), function: node.function, module: node.module]
    end

    def set_children(node, [props: props, function: function, module: module]) do
      IO.inspect [props: props, function: function, module: module, where: :set_children]
      %{node | props: :maps.from_list(props), function: function, module: node.module}
    end

    def compile(node, opts) do
      opts = opts ++ [debug: true]

      x = """
      _Props = #{Children.props(node.props, opts)},
      #{Children.call([node.module, node.function], opts)},
      
      case {#{Children.vars([node.module, node.function], opts)}} of
        {{#{ready}, Mod}, {#{ready}, Func}} ->
          io:put_chars([<<"DEBUG | ">>, <<" #{opts[:name]} :: ">>, [<<"calling ">>, atom_to_binary(Mod, utf8), <<".">>, atom_to_binary(Func, utf8), <<"(">>, 'Elixir.Enum':join('Elixir.Enum':map([_Props], fun etude_inspect/1), <<", ">>), <<")">>], <<"\n">>]),
          rebind(#{scope}) = {'Elixir.Etude.Runtime':hash({#{scope}, #{Children.vars([node.function], opts)}, #{Children.vars([node.module], opts)}}), 0},
          apply(Mod, Func, [#{op_args}, _Props]);
        #{Children.wildcard([node.function], opts)} ->
          io:put_chars([<<"DEBUG | ">>, <<" #{opts[:name]} :: ">>, [<<"waiting for function name for partial with props: ">>, 'Elixir.Enum':join('Elixir.Enum':map([_Props], fun etude_inspect/1), <<", ">>)], <<"\n">>]),
          {nil, #{state}}
      end
      """
      IO.puts "--------------"
      IO.puts x
      IO.puts "--------------"
      defop node, opts, [:memoize], x, Children.compile(Map.values(node.props) ++ [node.function, node.module], opts)
    end
  end
end
