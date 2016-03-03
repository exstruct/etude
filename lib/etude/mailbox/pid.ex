defimpl Etude.Mailbox, for: PID do
  def send(process, message) do
    :erlang.send(process, message)
    process
  end

  def stream!(process, timeout) do
    {timeout, &on_timeout/2}
    |> Stream.unfold(fn
      ({timeout, on_timeout}) ->
        receive do
          message ->
            {{message, process}, {0, &on_timeout_immediate/2}}
        after
          timeout ->
            on_timeout.(process, timeout)
        end
    end)
  end

  defp on_timeout(process, timeout) do
    raise Etude.Mailbox.TimeoutException, mailbox: process, timeout: timeout
  end

  defp on_timeout_immediate(_, _) do
    nil
  end
end
