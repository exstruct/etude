defmodule Etude.Serializer do
  defmacro __using__(_) do
    quote unquote: false, location: :keep do
      @compile :inline_list_funcs

      @ready Module.concat(__MODULE__, :__ETUDE_READY__)
      @thunk Module.concat(__MODULE__, :__ETUDE_THUNK__)

      defmodule Thunk do
        defstruct value: nil,
                  opts: nil
      end

      module = __MODULE__

      defimpl Etude.Thunk, for: __MODULE__.Thunk do
        def resolve(%{value: value, opts: opts}, state) do
          unquote(module).__serialize__(value, state, opts)
        end
      end

      def serialize(thunk, state, opts \\ []) do
        case Etude.Thunk.resolve(thunk, state) do
          {value, state} ->
            case __serialize__(value, state, opts) do
              {value, state} ->
                {finalize(value, opts), state}
              {:await, thunk, state} ->
                state = Etude.State.receive(state)
                serialize_recurse(thunk, state, opts)
            end
          {:await, thunk, state} ->
            state = Etude.State.receive(state)
            serialize(thunk, state, opts)
        end
      end

      defp serialize_recurse(thunk, state, opts) do
        case Etude.Thunk.resolve(thunk, state) do
          {value, state} ->
            {finalize(value, opts), state}
          {:await, thunk, state} ->
            state = Etude.State.receive(state)
            serialize_recurse(thunk, state, opts)
        end
      end

      defp encode(value, _) do
        value
      end
      defoverridable encode: 2

      defp finalize(value, _) do
        value
      end
      defoverridable finalize: 2

      def __serialize__(thunk, state, opts \\ [])
      def __serialize__(atom, state, opts) when is_atom(atom) do
        {encode(atom, opts), state}
      end
      def __serialize__(bin, state, opts) when is_binary(bin) do
        {encode(bin, opts), state}
      end
      def __serialize__(integer, state, opts) when is_integer(integer) do
        {encode(integer, opts), state}
      end
      def __serialize__(float, state, opts) when is_float(float) do
        {encode(float, opts), state}
      end
      def __serialize__([], state, opts) do
        {encode([], opts), state}
      end
      def __serialize__(list, state, opts) when is_list(list) do
        {ready?, list, state} = encode_list(list, {true, [], state}, opts)

        if ready? do
          {encode(list, opts), state}
        else
          {:await, %Thunk{value: list, opts: opts}, state}
        end
      end
      def __serialize__(%{__struct__: struct} = enum, state, opts) when struct in [Range, Stream] do
        __serialize__(Enum.to_list(enum), state, opts)
      end

      def __serialize__({}, state, opts) do
        {encode({}, opts), state}
      end
      for i <- 1..50 do
        tuple_values = Enum.map(1..i, &(:"value_#{&1}" |> Macro.var(nil)))

        def __serialize__(unquote({:{}, [], tuple_values}), state, opts) do
          {ready?, unquote(tuple_values), state} = encode_list(unquote(tuple_values), {true, [], state}, opts)
          tuple = unquote({:{}, [], tuple_values})

          if ready? do
            {encode(tuple, opts), state}
          else
            {:await, %Thunk{value: tuple, opts: opts}, state}
          end
        end
      end
      def __serialize__(tuple, state, opts) when is_tuple(tuple) do
        {ready?, values, state} = tuple |> :erlang.tuple_to_list |> encode_list({true, [], state}, opts)
        tuple = values |> :erlang.list_to_tuple()

        if ready? do
          {encode(tuple, opts), state}
        else
          {:await, %Thunk{value: tuple, opts: opts}, state}
        end
      end

      def __serialize__(map, state, opts) when map_size(map) == 0 do
        {encode(map, opts), state}
      end
      def __serialize__(%{__struct__: _} = other, state, opts) do
        handle_other(other, state, opts)
      end
      def __serialize__(map, state, opts) when is_map(map) do
        {ready?, map, state} = encode_map(map, state, opts)

        if ready? do
          {encode(map, opts), state}
        else
          {:await, %Thunk{value: map, opts: opts}, state}
        end
      end
      def __serialize__(other, state, opts) do
        handle_other(other, state, opts)
      end

      defp handle_other(thunk = %Thunk{}, state, opts) do
        Etude.Thunk.resolve(thunk, state)
      end
      defp handle_other(other, state, opts) do
        if Etude.Thunk.resolved?(other) do
          ## TODO call the etude serializer protocol here
          {encode(other, opts), state}
        else
          Etude.Thunk.resolve(other, state, &__serialize__(&1, &2, opts))
        end
      end

      defp encode_map(map, state, opts) do
        res = :maps.fold(fn(key, value, {ready?, map, state}) ->
          {ready?, key, state} = encode_nested_item(ready?, key, state, opts)
          {ready?, value, state} = encode_nested_item(ready?, value, state, opts)
          {ready?, :maps.put(key, value, map), state}
        end, {true, %{}, state}, map)

        case res do
          {true, map, state} ->
            {true, :maps.fold(fn({_, key}, {_, value}, map) ->
              :maps.put(key, value, map)
            end, %{}, map), state}
          _ ->
            res
        end
      end

      defp encode_list([], {true, acc, state}, _) do
        {true, :lists.foldl(fn({_, value}, acc) ->
          [value | acc]
        end, [], acc), state}
      end
      defp encode_list([], {false, acc, state}, _) do
        {false, :lists.reverse(acc), state}
      end
      defp encode_list([item | rest], {ready?, acc, state}, opts) do
        {ready?, value, state} = encode_nested_item(ready?, item, state, opts)
        encode_list(rest, {ready?, [value | acc], state}, opts)
      end

      defp encode_nested_item(ready?, {@ready, _} = item, state, _opts) do
        {ready?, item, state}
      end
      defp encode_nested_item(ready?, {@thunk, item}, state, opts) do
        case Etude.Thunk.resolve(item, state) do
          {value, state} ->
            {ready?, {@ready, value}, state}
          {:await, thunk, state} ->
            {false, {@thunk, thunk}, state}
        end
      end
      defp encode_nested_item(ready?, item, state, opts) do
        case __serialize__(item, state, opts) do
          {value, state} ->
            {ready?, {@ready, value}, state}
          {:await, thunk, state} ->
            {false, {@thunk, thunk}, state}
        end
      end
    end
  end
end
