defprotocol Etude.Traversable do
  @fallback_to_any true
  def traverse(value, mapper \\ &Etude.ok(&1))
end

defimpl Etude.Traversable, for: List do
  def traverse(list, map) do
    list
    |> gather([], map)
    |> Etude.chain(map)
  end

  defp gather([], acc, _map) do
    acc
    |> :lists.reverse()
    |> Etude.join()
  end
  defp gather([head | tail], acc, map) do
    head = @protocol.traverse(head, map)
    gather(tail, [head | acc], map)
  end
  defp gather(tail, acc, map) do
    head = Etude.join(acc)
    tail = @protocol.traverse(tail, map)
    [head, tail]
    |> Etude.join()
    |> Etude.map(fn([head, tail]) ->
      unwind(head, tail)
    end)
  end

  defp unwind([], acc) do
    acc
  end
  defp unwind([head | tail], acc) do
    unwind(tail, [head | acc])
  end
end

defimpl Etude.Traversable, for: [Map, Any] do
  def traverse(value, map) do
    :maps.fold(fn(key, value, acc) ->
      k = @protocol.traverse(key, map)
      v = @protocol.traverse(value, map)
      [k, v | acc]
    end, [], value)
    |> Etude.join()
    |> Etude.chain(fn(list) ->
      list
      |> list_to_map(%{})
      |> map.()
    end)
  end

  defp list_to_map([], acc) do
    acc
  end
  defp list_to_map([k, v | rest], acc) do
    acc = Map.put(acc, k, v)
    list_to_map(rest, acc)
  end
end

defimpl Etude.Traversable, for: Tuple do
  def traverse(value, map) do
    value
    |> :erlang.tuple_to_list()
    |> Enum.map(&@protocol.traverse(&1, map))
    |> Etude.join()
    |> Etude.map(&:erlang.list_to_tuple/1)
    |> Etude.chain(map)
  end
end

defimpl Etude.Traversable, for: [Atom, BitString, Float, Function, Integer, Pid, Port, Reference] do
  def traverse(value, map) do
    map.(value)
  end
end
