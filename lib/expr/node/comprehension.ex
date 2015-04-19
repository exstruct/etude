defmodule Expr.Node.Comprehension do
  defstruct collection: [],
            key: nil,
            value: nil,
            expression: nil,
            type: :list,
            line: 1

  defimpl Expr.Node, for: Expr.Node.Comprehension do
    alias Expr.Children
    alias Expr.Utils
    alias Expr.Node.Comprehension
    import Expr.Vars

    defdelegate call(node, opts), to: Expr.Node.Any
    defdelegate assign(node, opts), to: Expr.Node.Any
    defdelegate var(node, opts), to: Expr.Node.Any
    defdelegate name(node, opts), to: Expr.Node.Any

    def compile(node, opts) do
      name = Expr.Node.name(node, opts)
      exec = "#{name}_exec" |> String.to_atom
      collection = node.collection

      children = [
        collection,
        node.expression,
        node.key,
        node.value
      ]

      quote line: node.line do
        defp unquote(name)(unquote_splicing(op_args)) do
          Expr.Memoize.wrap unquote(name) do
            ## dependencies
            unquote(Expr.Node.assign(collection, opts))

            ## exec
            unquote(exec)(unquote(Expr.Node.var(collection, opts)), unquote_splicing(op_args))
          end
        end

        defp unquote(exec)({unquote(Utils.ready), :undefined}, unquote_splicing(op_args)) do
          Logger.debug(unquote("#{name} undefined"))
          {{unquote(Utils.ready), :undefined}, unquote(state)}
        end
        defp unquote(exec)({unquote(Utils.ready), unquote(coll)}, unquote_splicing(op_args)) when unquote(coll) in [false, nil] do
          Logger.debug(unquote("#{name} empty"))
          {unquote(get_default(node)), unquote(state)}
        end
        defp unquote(exec)({unquote(Utils.ready), unquote(coll)}, unquote_splicing(op_args)) do
          case unquote(reduce(node, opts)) do
            {nil, state} ->
              Logger.debug(unquote("#{name} pending"))
              {nil, state}
            {val, state} ->
              Logger.debug(fn -> unquote("#{name} result -> ") <> inspect(val) end)
              {{unquote(Utils.ready), val}, state}
          end
        end
        defp unquote(exec)(_, unquote_splicing(op_args)) do
          {nil, unquote(state)}
        end

        unquote_splicing(Children.compile(children, opts))
      end
    end

    defp reduce(node, opts) do
      expression = node.expression
      quote do
        ## TODO type check the collection to see if it's key, value
        {_, acc, state} = Enum.reduce(unquote(coll), {0, [], unquote(state)}, fn
          ## something didn't finish but we're going to play the rest out
          (unquote(item), {unquote(i), nil, unquote(state)}) ->
            unquote(child_scope(:item))
            unquote(assign_vars(node, opts))
            unquote(Expr.Node.assign(expression, opts))
            {unquote(i) + 1, nil, unquote(state)}
          (unquote(item), {unquote(i), acc, unquote(state)}) ->
            ## create a new scope based on the item's value
            unquote(child_scope(:item))

            ## assign iterator variables to the scope
            unquote(assign_vars(node, opts))

            ## dependency
            unquote(Expr.Node.assign(expression, opts))
            case unquote(Expr.Node.var(expression, opts)) do
              nil ->
                {unquote(i) + 1, nil, unquote(state)}
              {unquote(Utils.ready), val} ->
                {unquote(i) + 1, [val | acc], unquote(state)}
            end
        end)
        acc = :lists.reverse(acc)
        unquote(convert_to_type(node))
        {acc, state}
      end
    end

    defp assign_vars(%Comprehension{key: nil, value: nil}, _) do
      []
    end
    defp assign_vars(%Comprehension{key: nil, value: value}, opts) do
      v = Expr.Node.Assign.resolve(value, opts)
      [quote do
        Expr.Memoize.put(unquote(v), {unquote(Utils.ready), unquote(item)})
      end]
    end
    defp assign_vars(%Comprehension{key: key, value: value}, opts) do
      v = Expr.Node.Assign.resolve(value, opts)
      k = Expr.Node.Assign.resolve(key, opts)
      quote do
        Expr.Memoize.put(unquote(k), {unquote(Utils.ready), unquote(i)})
        Expr.Memoize.put(unquote(v), {unquote(Utils.ready), unquote(item)})
      end
    end

    defp get_default(%Comprehension{type: :list}) do
      {Utils.ready, []}
    end
    defp get_default(%Comprehension{type: :map}) do
      {Utils.ready, Macro.escape(%{})}
    end
    defp get_default(%Comprehension{type: :tuple}) do
      {Utils.ready, Macro.escape({})}
    end

    defp convert_to_type(%Comprehension{type: :list}) do
      nil
    end
    defp convert_to_type(%Comprehension{type: type}) do
      {mod, fun} = type_from_list(type)
      quote do
        acc = case acc do
          nil ->
            nil
          val ->
            unquote(mod).unquote(fun)(val)
        end
      end
    end

    defp type_from_list(:map) do
      {:maps, :from_list}
    end
    defp type_from_list(:tuple) do
      {:erlang, :list_to_tuple}
    end
    defp type_from_list(type) do
      ## TODO should we make this a protocol?
      {type, :from_list}
    end

    defp item do
      Macro.var(:item, nil)
    end
    defp i do
      Macro.var(:i, nil)
    end
    defp coll do
      Macro.var(:coll, nil)
    end
  end
end