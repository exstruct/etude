defprotocol Etude.Mailbox do
  def send(mailbox, message)

  Kernel.def stream!(mailbox, timeout \\ 10_000)
  def stream!(mailbox, timeout)
end

defmodule Etude.Mailbox.TimeoutException do
  defexception [:mailbox, :timeout]

  def message(%{mailbox: nil, timeout: timeout}) do
    "Mailbox did not receive message within #{timeout}ms"
  end
  def message(%{mailbox: mailbox, timeout: timeout}) do
    "Mailbox #{inspect(mailbox)} did not receive message within #{timeout}ms"
  end
end
