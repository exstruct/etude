defprotocol Etude.Mailbox do
  def send(mailbox, message)

  Kernel.def stream!(mailbox, timeout \\ 10_000)
  def stream!(mailbox, timeout)
end
