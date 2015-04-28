defmodule Etude.Node.Comprehension do
  defstruct collection: [],
            key: nil,
            value: nil,
            expression: nil,
            type: :list,
            line: 1

  alias Etude.Children
  alias Etude.Node.Comprehension
  import Etude.Vars
  import Etude.Utils

  defimpl Etude.Node, for: Etude.Node.Comprehension do
    defdelegate call(node, opts), to: Etude.Node.Any
    defdelegate assign(node, opts), to: Etude.Node.Any
    defdelegate prop(node, opts), to: Etude.Node.Any
    defdelegate var(node, opts), to: Etude.Node.Any
    defdelegate name(node, opts), to: Etude.Node.Any

    def compile(node, opts) do
      name = Etude.Node.name(node, opts)
      exec = "#{name}_exec" |> String.to_atom
      collection = node.collection

      children = [
        collection,
        node.expression,
        node.key,
        node.value
      ]

      defop node, opts, [:memoize], """
      #{Children.call([collection], opts)},
      case #{exec}(#{Children.vars([collection], opts, ", ")}#{op_args}) of
        {nil, PendingState} ->
          ?DEBUG(<<"#{name} comprehension pending">>),
          {nil, PendingState};
        CollRes ->
          #{debug_res(name, "element(1, CollRes)", "comprehension")},
          CollRes
      end
      """, Dict.put(Children.compile(children, opts), exec, compile_exec(exec, node, opts))
    end

    defp compile_exec(name, node, opts) do
      """
      #{name}({#{ready}, undefined}, #{op_args}) ->
        {{#{ready}, undefined}, #{state}};
      #{name}({#{ready}, nil}, #{op_args}) ->
        {{#{ready}, #{get_default(node)}}, #{state}};
      #{name}({#{ready}, false}, #{op_args}) ->
        {{#{ready}, #{get_default(node)}}, #{state}};
      #{name}({#{ready}, Collection}, #{op_args("InitialState")}) ->
        ?DEBUG([<<"#{name} comprehension in ">>, ?INSPECT(Collection)]),
        case 'Elixir.Enum':reduce(Collection, {0, [], InitialState}, fun
      #{indent(reduce_clauses(node, opts), 2)}
        end) of
          {_, nil, NilState} ->
            {nil, NilState};
          {_, Val, ValState} ->
            ?DEBUG([<<"#{name} comprehension out ">>, ?INSPECT(Val)]),
            Reversed = lists:reverse(Val),
      #{indent(convert_to_type(node, "Reversed"), 3)},
            {{#{ready}, Reversed}, ValState}
        end;
      #{name}(_, #{op_args}) ->
        {nil, #{state}}.
      """
    end

    defp reduce_clauses(node, opts) do
      """
      ({_Key, _Item}, {Index, nil, #{state}}) ->
      #{indent(reduce_nil(node, opts))};
      (_Item, {_Key = Index, nil, #{state}}) ->
      #{indent(reduce_nil(node, opts))};
      ({_Key, _Item}, {Index, Acc, #{state}}) ->
      #{indent(reduce_acc(node, opts))};
      (_Item, {_Key = Index, Acc, #{state}}) ->
      #{indent(reduce_acc(node, opts))}
      """
    end

    defp reduce_nil(node, opts) do
      expression = Children.call([node.expression], opts)
      """
      #{create_child_scope(node)},
      #{assign_vars(node, opts)},
      #{expression},
      {Index + 1, nil, #{state}}
      """
    end

    defp reduce_acc(node, opts) do
      expression = Children.call([node.expression], opts)
      var = Etude.Node.var(node.expression, opts)
      """
      #{create_child_scope(node)},
      #{assign_vars(node, opts)},
      #{expression},
      case #{var} of
        nil ->
          {Index + 1, nil, #{state}};
        {#{ready}, Val} ->
          {Index + 1, [Val | Acc], #{state}}
      end
      """
    end

    def create_child_scope(%Comprehension{key: nil, value: nil}) do
      "nil"
    end
    def create_child_scope(%Comprehension{key: nil, value: _}) do
      child_scope("_Item")
    end
    def create_child_scope(%Comprehension{key: _, value: nil}) do
      child_scope("_Key")
    end
    def create_child_scope(_) do
      child_scope(["_Item", "_Key"])
    end

    defp assign_vars(%Comprehension{key: nil, value: nil}, _) do
      "nil"
    end
    defp assign_vars(%Comprehension{key: nil, value: value}, opts) do
      v = Etude.Node.Assign.resolve(value, opts)
      "?MEMO_PUT(#{req}, #{v}, #{scope}, {#{ready}, _Item})"
    end
    defp assign_vars(%Comprehension{key: key, value: value}, opts) do
      v = Etude.Node.Assign.resolve(value, opts)
      k = Etude.Node.Assign.resolve(key, opts)
      "?MEMO_PUT(#{req}, #{v}, #{scope}, {#{ready}, _Item}),\n?MEMO_PUT(#{req}, #{k}, #{scope}, {#{ready}, _Key})"
    end

    defp get_default(%Comprehension{type: :list}) do
      "[]"
    end
    defp get_default(%Comprehension{type: :map}) do
      "\#{}"
    end
    defp get_default(%Comprehension{type: :tuple}) do
      "{}"
    end

    defp convert_to_type(%Comprehension{type: :list}, _var) do
      "nil"
    end
    defp convert_to_type(%Comprehension{type: type}, var) do
      {mod, fun} = type_from_list(type)
      """
      rebind(#{var}) = case #{var} of
        nil -> nil;
        ConvertedVal -> #{escape(mod)}:#{escape(fun)}(ConvertedVal)
      end
      """
    end

    defp type_from_list(:map) do
      {:maps, :from_list}
    end
    defp type_from_list(:tuple) do
      {:erlang, :list_to_tuple}
    end
  end
end