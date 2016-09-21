defprotocol Etude.Traversable do
  def traverse(value, mapper \\ &Etude.Future.of(&1))
end

defimpl Etude.Traversable, for: Etude.Future do
  def traverse(value, map) do
    Etude.Future.chain(value, fn(value) ->
      @protocol.traverse(value, map)
    end)
  end
end

defimpl Etude.Traversable, for: List do
  def traverse(list, map) do
    list
    |> gather([], map)
    |> Etude.Future.chain(map)
  end

  defp gather([], acc, _map) do
    acc
    |> :lists.reverse()
    |> Etude.Future.parallel()
  end
  defp gather([head | tail], acc, map) do
    head = @protocol.traverse(head, map)
    gather(tail, [head | acc], map)
  end
  defp gather(tail, acc, map) do
    head = Etude.Future.parallel(acc)
    tail = @protocol.traverse(tail, map)
    [head, tail]
    |> Etude.Future.parallel()
    |> Etude.Future.map(fn([head, tail]) ->
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
    |> Etude.Future.parallel()
    |> Etude.Future.chain(fn(list) ->
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
    |> Etude.Future.parallel()
    |> Etude.Future.map(&:erlang.list_to_tuple/1)
    |> Etude.Future.chain(map)
  end
end

defimpl Etude.Traversable, for: [Atom, BitString, Float, Function, Integer, Pid, Port, Reference] do
  def traverse(value, map) do
    value
    |> Etude.Future.of()
    |> Etude.Future.chain(map)
  end
end
