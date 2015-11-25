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
      # IO.inspect [props: :maps.to_list(node.props), function: node.function, module: node.module, where: :children]
      [props: :maps.to_list(node.props), function: node.function, module: node.module]
    end

    def set_children(node, [props: props, function: function, module: module]) do
      # IO.inspect [props: props, function: function, module: module, where: :set_children]
      %{node | props: :maps.from_list(props), function: function, module: module}
    end

    def compile(node, opts) do
      opts = opts ++ [debug: true]



# %{arg: {['module_name'], ['function_name_partial'],
#    %{feature: :feature_offers, user_id: $user_id}}, scope: 100501959}
# rebind(_Scope) = {'Elixir.Etude.Runtime':hash({_Scope, 100501959}), 0}




      # mod = escape(:module_name)
      # fun_a = "function_name_partial" |> String.to_atom
      # fun = escape(fun_a)
      # props = node.props
      # scope = Etude.Runtime.hash({mod, fun, props})
      # IO.inspect %{arg: {mod, fun, props}, scope: scope}
      # IO.inspect(Etude.Runtime.prepare_hash(props))
      # IO.inspect(Etude.Runtime.prepare_hash(Etude.Runtime.prepare_hash(props)))
      # IO.puts(:io_lib.format("~w", [props]))

      # props_for_hash = node.props
      # |> Enum.map(fn
      #   {name, value} when is_atom(value) ->
      #     "#{name} => #{value}"
      #   {name, value} ->
      #     "#{name} => #{inspect value}"
      # end)
      # |> Enum.join(", ")

      IO.inspect(Etude.Runtime.prepare_hash(node.props))
      IO.puts :io_lib.format("~w", [node.props])
      IO.puts :io_lib.format("~w", [Etude.Runtime.prepare_hash(node.props)])

      x = """
      _Props = #{Children.props(node.props, opts)},
      #{Children.call([node.module, node.function], opts)},
      
      case {#{Children.vars([node.module, node.function], opts)}} of
        {{#{ready}, Mod}, {#{ready}, Func}} ->
          PartialFunc = binary_to_atom(iolist_to_binary([atom_to_binary(Func, utf8), <<"_partial">>]), utf8),
          Hash = 'Elixir.Etude.Runtime':hash({'Elixir.Etude.Utils':escape(Mod), 'Elixir.Etude.Utils':escape(PartialFunc), #{:io_lib.format("~w", [node.props])}}),
          rebind(#{scope}) = {'Elixir.Etude.Runtime':hash({#{scope}, Hash}), 0},
          io:put_chars([<<"DEBUG | ">>, <<" #{opts[:name]} :: ">>, [<<"calling ">>, atom_to_binary(Mod, utf8), <<".">>, atom_to_binary(PartialFunc, utf8), <<"(">>, 'Elixir.Enum':join('Elixir.Enum':map([_Props], fun etude_inspect/1), <<", ">>), <<")">>], <<"\n">>]),
          apply(Mod, PartialFunc, [#{op_args}, _Props]);
        _ ->
          io:put_chars([<<"DEBUG | ">>, <<" #{opts[:name]} :: ">>, [<<"waiting for function name for partial with props: ">>, 'Elixir.Enum':join('Elixir.Enum':map([_Props], fun etude_inspect/1), <<", ">>)], <<"\n">>]),
          {nil, #{state}}
      end
      """
      IO.puts "--------------"
      IO.puts x
      IO.puts "--------------"
      defop node, opts, [:memoize], x, Children.compile([node.module, node.function | Map.values(node.props)], opts)
    end
  end
end
