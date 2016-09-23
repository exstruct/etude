defmodule Etude.Unifiable do
  alias Etude.Future
  alias Etude.Match.Error

  def unify(a, a, _) do
    a
  end
  def unify(a, b, binding) do
    if !Future.forkable?(a) && !Future.forkable?(b) do
      Future.error(%Error{term: b, binding: binding})
    else
      [
        Future.to_term(a),
        Future.to_term(b)
      ]
      |> Future.parallel()
      |> Future.chain(fn([a, b]) ->
        compare(a, b, binding)
      end)
    end
  end

  defp compare(a, a, _) do
    Future.of(a)
  end
  defp compare([], [], _) do
    Future.of([])
  end
  defp compare(a, b, binding) when is_list(a) and is_list(b) do
    compare_lists(a, b, [], binding)
  end
  defp compare(a, b, binding) when is_tuple(a) and is_tuple(b) and tuple_size(a) == tuple_size(b) do
    a = :erlang.tuple_to_list(a)
    b = :erlang.tuple_to_list(b)
    compare_lists(a, b, [], binding)
    |> Future.map(&:erlang.list_to_tuple/1)
  end
  defp compare(a, b, binding) when is_map(a) and is_map(b) and map_size(a) == map_size(b) do
    a = :maps.to_list(a)
    b = :maps.to_list(b)
    compare_lists(a, b, [], binding)
    |> Future.map(&:maps.from_list/1)
  end
  defp compare(_, b, binding) do
    Future.error(%Error{term: b, binding: binding})
  end

  defp compare_lists([], [], acc, _) do
    acc
    |> :lists.reverse()
    |> Future.parallel()
  end
  defp compare_lists([a_h | a_t], [b_h | b_t], acc, binding) do
    compare_lists(a_t, b_t, [unify(a_h, b_h, binding) | acc], binding)
  end
  defp compare_lists([], b, _, binding) do
    Future.error(%Error{term: b, binding: binding})
  end
  defp compare_lists(_, [], _, binding) do
    Future.error(%Error{term: [], binding: binding})
  end
end
