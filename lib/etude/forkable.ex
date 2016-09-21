defprotocol Etude.Forkable do
  @fallback_to_any true
  def fork(future, state, rej, res)
end

defimpl Etude.Forkable, for: Etude.Future do
  alias Etude.State

  def fork(%{guarded: true} = f, state, rej, res) do
    ref = :erlang.unique_integer()
    {state, cancel} = fork(%{f | guarded: false}, state, once(rej, ref), once(res, ref))

    {state, fn(%{private: private} = state) ->
      case Map.fetch(private, ref) do
        {:ok, true} ->
          state
        :error ->
          state
          |> cancel.()
          |> State.put_private(ref, true)
      end
    end}
  end
  def fork(%{fun: fun}, state, rej, res) do
    case fun.(state, rej, res) do
      {state, cancel} ->
        {state, cancel}
      %Etude.State{} = state ->
        {state, fn(s) -> s end}
    end
  end

  defp once(fun, ref) do
    fn(%{private: private} = state, value) ->
      case Map.fetch(private, ref) do
        {:ok, true} ->
          state
        :error ->
          state = State.put_private(state, ref, true)
          fun.(state, value)
      end
    end
  end
end

defimpl Etude.Forkable, for: Any do
  def fork(value, state, _rej, res) do
    res.(state, value)
  end
end
