defmodule Etude.Mailbox do
  @moduledoc false
  alias Etude.State

  defmodule Timeout do
    defexception [:timeout, :pid]

    def message(%{pid: pid, timeout: timeout}) do
      "Mailbox #{inspect(pid)} did not receive a message after #{inspect(timeout)}ms"
    end
  end

  def receive_into(state, timeout \\ 10_000) do
    receive do
      message ->
        state
        |> State.handle_info(message)
        |> receive_immediate()
    after
      timeout ->
        raise Timeout, timeout: timeout, pid: self()
    end
  end

  defp receive_immediate(state) do
    receive do
      message ->
        state
        |> State.handle_info(message)
        |> receive_immediate()
    after
      0 ->
        state
    end
  end
end
