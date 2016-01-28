defmodule Etude.Serializer do
  defmacro __using__(opts) do
    quote do
      alias unquote(opts[:encoder]), as: Encoder

      def serialize(thunk, state, opts \\ [])
      def serialize(atom, state, opts) when is_atom(atom) do
        {Encoder.encode(atom, opts), state}
      end
      def serialize(bin, state, opts) when is_binary(bin) do
        {Encoder.encode(bin, opts), state}
      end
      def serialize(integer, state, opts) when is_integer(integer) do
        {Encoder.encode(integer, opts), state}
      end
      def serialize(float, state, opts) when is_float(float) do
        {Encoder.encode(float, opts), state}
      end
      def serialize([], state, _opts) do
        {"[]", state}
      end
      def serialize(list, state, opts) when is_list(list) do
        {ready?, list, state} = :lists.foldl(&encode_list_item(&1, &2, opts), {true, [], state}, list)

        if ready? do
          {[?[, tl(:lists.foldl(&[?,, &1 | &2], [], list)), ?]], state}
        else
          {:await, %Etude.Thunk.Continuation{
                      function: &serialize(&1, &2, opts),
                      arguments: list}, state}
        end
      end

      ## TODO add Range, Stream, and HashSet
      ## TODO add HashDict

      def serialize(map, state, _opts) when map_size(map) < 1 do
        {"{}", state}
      end
      def serialize(map, state, _opts) when is_map(map) do
        {"__MAP__", state}
      end
      def serialize(other, state, opts) do
        if Etude.Thunk.resolved?(other) do
          {Encoder.encode(other, opts), state}
        else
          Etude.Thunk.resolve(other, state, &serialize(&1, &2, opts))
        end
      end

      defp encode_list_item(item, {ready?, acc, state}, opts) do
        case serialize(item, state, opts) do
          {value, state} ->
            {ready?, [value | acc], state}
          {:await, thunk, state} ->
            {false, [thunk | acc], state}
        end
      end
    end
  end
end
