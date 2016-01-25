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
    Logger.warn("Unhandled message #{inspect(receivable)}")

    %{state | receivers: acc}
  end
  defp match_receivable(receivable, [{:permanent, fun} = receiver | receivers] = remaining, state, acc) do
    case fun.(receivable, state) do
      nil ->
        match_receivable(receivable, receivers, state, [receiver | acc])
      state ->
        %{state | receivers: :lists.reverse(remaining) ++ acc}
    end
  end
  defp match_receivable(receivable, [receiver | receivers], state, acc) do
    case receiver.(receivable, state) do
      nil ->
        match_receivable(receivable, receivers, state, [receiver | acc])
      state ->
        %{state | receivers: :lists.reverse(receivers) ++ acc}
    end
  end
end
