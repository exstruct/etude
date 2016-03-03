defmodule Etude.Serializer.JSON do
  use Etude.Serializer

  defp finalize(:undefined, _) do
    ""
  end
  defp finalize(value, _) do
    value
  end

  defp encode(nil, _), do: "null"
  defp encode(true, _), do: "true"
  defp encode(false, _), do: "false"
  defp encode(:undefined, _), do: :undefined
  defp encode(atom, _) when is_atom(atom) do
    Poison.Encoder.BitString.encode(Atom.to_string(atom), [])
  end

  defp encode("", _), do: "\"\""
  defp encode(bin, _) when is_binary(bin) do
    Poison.Encoder.BitString.encode(bin, [])
  end
  defp encode(integer, _) when is_integer(integer) do
    Integer.to_string(integer)
  end
  defp encode(float, _) when is_float(float) do
    :io_lib_format.fwrite_g(float)
  end

  defp encode([], _), do: "[]"
  defp encode(list, _) when is_list(list) do
    [?[, tl(:lists.foldr(fn
      (:undefined, acc) ->
        [?,, "null" | acc]
      (value, acc) ->
        [?,, value | acc]
    end, [], list)), ?]]
  end

  defp encode(map, _) when map_size(map) == 0, do: "{}"
  defp encode(map, _) when is_map(map) do
    :maps.fold(fn
      (:undefined, _, acc) ->
        acc
      (_, :undefined, acc) ->
        acc
      ([34, _, 34] = key, value, acc) ->
        [?,, key, ?:, value | acc]
      ("\"\"" = key, value, acc) ->
        [?,, key, ?:, value | acc]
      (key, value, acc) when is_binary(key) ->
        [?,, Poison.Encoder.BitString.encode(key, []), ?:, value | acc]
    end, [], map)
    |> encode_map_result()
  end

  defp encode_map_result([]), do: "{}"
  defp encode_map_result(data), do: [?{, tl(data), ?}]
end
