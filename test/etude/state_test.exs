defmodule Test.Etude.State do
  use Test.Etude.Case
  alias Etude.State

  test "memoize" do
    assertion = fn({value, state}) ->
      assert value == 123
      state
    end

    %State{}
    |> State.memoize({:foo, 1}, fn() ->
      123
    end)
    |> assertion.()
    |> State.memoize({:foo, 1}, fn() ->
      flunk "The state did not memoize the call"
    end)
    |> assertion.()
    |> State.cleanup()
  end

  test "mailbox send" do
    state = %State{mailbox: []}

    state = state
    |> State.send(:world)
    |> State.send(:hello)

    assert [:hello, :world] == state.mailbox

    State.cleanup(state)
  end

  test "mailbox receive" do
    receiver = fn
      (value, state) ->
        State.put_private(state, value, true)
    end

    state = %State{mailbox: []}
    |> State.add_receiver(receiver)
    |> State.send(:hello)
    |> State.add_receiver(receiver)
    |> State.send(:world)
    |> State.receive()

    assert %{hello: true, world: true} == state.private

    State.cleanup(state)
  end
end
