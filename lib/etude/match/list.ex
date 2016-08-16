defimpl Etude.Matchable, for: List do
  alias Etude.Match.{Literal,Utils}

  def compile([]) do
    Literal.compile([])
  end
  def compile([head | tail]) do
    head_p = @protocol.compile(head)
    tail_p = @protocol.compile(tail)
    &exec(head_p, tail_p, &1, &2, &3)
  end

  def compile_body([]) do
    Literal.compile_body([])
  end
  def compile_body([head | tail]) do
    head_b = @protocol.compile_body(head)
    tail_b = @protocol.compile_body(tail)
    fn(state, b) ->
      case head_b.(state, b) do
        {:ok, head, state} ->
          case tail_b.(state, b) do
            {:ok, tail, state} ->
              {:ok, [head | tail], state}
            error ->
              error
          end
        error ->
          error
      end
    end
  end

  defp exec(_, _, [], state, _) do
    {:ok, [], state}
  end
  defp exec(head_p, tail_p, [head | tail], state, b) do
    case head_p.(head, state, b) do
      {:ok, head, state} ->
        case tail_p.(tail, state, b) do
          {:ok, tail, state} ->
            {:ok, [head | tail], state}
          {:await, thunk, state} ->
            {:await, [head | thunk], state}
          {:error, state} ->
            {:error, state}
        end
      {:await, thunk, state} ->
        ## TODO OPTIMIZE we should keep going and evaluating down the tail so we get parallel eval
        Utils.continuation(thunk, state, (&exec(head_p, tail_p, [&1 | tail], &2, b)))
      {:error, state} ->
        {:error, state}
    end
  end
  defp exec(head_p, tail_p, value, state, b) do
    Etude.Thunk.resolve(value, state, fn
      (value, state) when is_list(value) ->
        exec(head_p, tail_p, value, state, b)
      (_, state) ->
        {:error, state}
    end)
  end
end
