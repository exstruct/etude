defprotocol Etude.Receivable do
  @fallback_to_any true
  def receive_into(receivable, state)
end

defimpl Etude.Receivable, for: Any do
  require Logger

  def receive_into(receivable, %{receivers: receivers} = state) do
    match_receivable(receivable, :lists.reverse(receivers), state, [])
  end

  defp match_receivable(receivable, [], state, acc) do
    state.unhandled_warning &&
      Logger.warn("Unhandled message in #{inspect(self)}: #{inspect(receivable)}")

    %{state | receivers: acc}
  end
  defp match_receivable(receivable, [receiver | receivers] = remaining, state, acc) do
    case receiver.(state, receivable) do
      nil ->
        match_receivable(receivable, receivers, state, [receiver | acc])
      {:done, %Etude.State{} = state} ->
        %{state | receivers: :lists.reverse(receivers) ++ acc}
      %Etude.State{} = state ->
        %{state | receivers: :lists.reverse(remaining) ++ acc}
    end
  end
end
