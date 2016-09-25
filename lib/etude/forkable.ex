defprotocol Etude.Forkable do
  @fallback_to_any true
  def fork(future, state, stack)
end

defimpl Etude.Forkable, for: Any do
  def fork(value, state, _) do
    {:ok, value, state}
  end
end
