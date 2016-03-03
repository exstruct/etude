defmodule Test.Etude.Mailbox do
  use Test.Etude.Case
  alias Etude.Mailbox
  alias Etude.State

  for {name, mailbox} <- [{"pid", quote(do: self())},
                          {"list", quote(do: [])},
                          {"state (pid)", quote(do: %State{mailbox: self()})},
                          {"state (list)", quote(do: %State{mailbox: []})}] do
    test "#{name} sends and receives messages" do
      mailbox = unquote(mailbox)
      |> Mailbox.send(1)
      |> Mailbox.send(2)
      |> Mailbox.send(3)
      |> Mailbox.send(4)
      |> Mailbox.send(5)

      messages = mailbox
      |> Mailbox.stream!()
      |> Enum.map(fn({value, _}) ->
        value
      end)

      assert messages == [1,2,3,4,5]
    end
  end

  test "process raises after timing out" do
    assert_raise Etude.Mailbox.PID.TimeoutException, fn ->
      self
      |> Mailbox.stream!(1)
      |> Enum.to_list()
    end
  end
end
