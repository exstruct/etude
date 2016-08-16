defimpl Etude.Matchable, for: Tuple do
  alias Etude.Match.Utils

  def compile({}) do
    Etude.Match.Literal.compile({})
  end
  def compile(tuple) do
    patterns = :erlang.tuple_to_list(tuple) |> Enum.map(&@protocol.compile/1)
    match = &exec(patterns, 0, &1, &2, &3)
    size = tuple_size(tuple)

    fn(value, state, b) ->
      Etude.Thunk.resolve(value, state, fn
        (value, state) when is_tuple(value) and tuple_size(value) == size ->
          match.(value, state, b)
        (_, state) ->
          {:error, state}
      end)
    end
  end

  def compile_body(tuple) do
    bodies = :erlang.tuple_to_list(tuple) |> Enum.map(&@protocol.compile_body/1)
    init = :erlang.make_tuple(tuple_size(tuple), nil)
    &exec_body(bodies, 0, init, &1, &2)
  end

  defp exec([], _, tuple, state, _) do
    {:ok, tuple, state}
  end
  defp exec([pattern | patterns] = all, idx, tuple, state, b) do
    case pattern.(elem(tuple, idx), state, b) do
      {:ok, value, state} ->
        exec(patterns, idx + 1, put_elem(tuple, idx, value), state, b)
      {:await, thunk, state} ->
        ## TODO OPTIMIZE keep going here
        Utils.continuation(thunk, state, (&exec(all, idx, put_elem(tuple, idx, &1), &2, b)))
      {:error, state} ->
        {:error, state}
    end
  end

  defp exec_body([], _, tuple, state, _) do
    {:ok, tuple, state}
  end
  defp exec_body([body | bodies], idx, tuple, state, b) do
    case body.(state, b) do
      {:ok, v, state} ->
        exec_body(bodies, idx + 1, put_elem(tuple, idx, v), state, b)
      error ->
        error
    end
  end
end
