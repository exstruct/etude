defprotocol Etude.Mailbox do
  def send(mailbox, message)
  def stream!(mailbox, timeout)
end
