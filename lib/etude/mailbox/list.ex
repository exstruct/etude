defimpl Etude.Mailbox, for: List do
  def send(list, message) do
    [message | list]
  end

  def stream!(list, _) do
    list
    |> :lists.reverse()
    |> Stream.unfold(fn
      ([]) ->
        nil
      ([message | list]) ->
        {{message, list}, list}
    end)
  end
end
