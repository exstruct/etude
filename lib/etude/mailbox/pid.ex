defimpl Etude.Mailbox, for: PID do
  defmodule TimeoutException do
    defexception [:timeout]

    def message(%{timeout: timeout}) do
      "Process did not receive message within #{timeout}ms"
    end
  end

  def send(process, message) do
    :erlang.send(process, message)
    process
  end

  def stream!(process, timeout) do
    {timeout, &on_timeout/1}
    |> Stream.unfold(fn
      ({timeout, on_timeout}) ->
        receive do
          message ->
            {{message, process}, {0, &on_timeout_immediate/1}}
        after
          timeout ->
            on_timeout.(timeout)
        end
    end)
  end

  defp on_timeout(timeout) do
    raise __MODULE__.TimeoutException, timeout: timeout
  end

  defp on_timeout_immediate(_) do
    nil
  end
end
