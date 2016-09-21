defmodule Etude.Unifiable do
  alias Etude.Future

  def unify(a, a) do
    a
  end
  def unify(a, b) do
    if !Future.forkable?(a) && !Future.forkable?(b) do
      Future.reject({a, b})
    else
      [
        Future.to_term(a),
        Future.to_term(b)
      ]
      |> Future.parallel()
      |> Future.chain(fn([a, b]) ->
        compare(a, b)
      end)
    end
  end

  defp compare(a, a) do
    Future.of(a)
  end
  defp compare([], []) do
    Future.of([])
  end
  defp compare(a, b) when is_list(a) and is_list(b) do
    compare_lists(a, b, [])
  end
  defp compare(a, b) when is_tuple(a) and is_tuple(b) and tuple_size(a) == tuple_size(b) do
    a = :erlang.tuple_to_list(a)
    b = :erlang.tuple_to_list(b)
    compare_lists(a, b, [])
    |> Future.map(&:erlang.list_to_tuple/1)
  end
  defp compare(a, b) when is_map(a) and is_map(b) and map_size(a) == map_size(b) do
    a = :maps.to_list(a)
    b = :maps.to_list(b)
    compare_lists(a, b, [])
    |> Future.map(&:maps.from_list/1)
  end
  defp compare(a, b) do
    Future.reject({a, b})
  end

  defp compare_lists([], [], acc) do
    acc
    |> :lists.reverse()
    |> Future.parallel()
  end
  defp compare_lists([a_h | a_t], [b_h | b_t], acc) do
    compare_lists(a_t, b_t, [unify(a_h, b_h) | acc])
  end
end
