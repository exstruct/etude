defmodule Test.Etude.State do
  use Test.Etude.Case
  alias Etude.State
  alias Etude.Cache
  alias Etude.Mailbox

  test "memoize" do
    assertion = fn({:ok, value, state}) ->
      assert value == 123
      state
    end

    %State{}
    |> Cache.memoize({:foo, 1}, fn() ->
      123
    end)
    |> assertion.()
    |> Cache.memoize({:foo, 1}, fn() ->
      flunk "The state did not memoize the call"
    end)
    |> assertion.()
    |> State.cleanup()
  end

  test "mailbox send" do
    state = %State{mailbox: []}

    state = state
    |> Mailbox.send(:world)
    |> Mailbox.send(:hello)

    assert [:hello, :world] == state.mailbox

    State.cleanup(state)
  end

  test "mailbox receive" do
    receiver = fn
      (value, state) ->
        {:done, State.put_private(state, value, true)}
    end

    state = %State{mailbox: []}
    |> State.add_receiver(receiver)
    |> Mailbox.send(:hello)
    |> State.add_receiver(receiver)
    |> Mailbox.send(:world)
    |> State.receive()

    assert %{hello: true, world: true} == state.private

    State.cleanup(state)
  end

  test "timeout exception" do
    assert_raise Etude.State.TimeoutException, fn ->
      %State{mailbox: self()}
      |> Mailbox.stream!(1)
      |> Enum.to_list()
    end
  end

  test "reducers" do
    state = %State{mailbox: []}
    |> State.add_reducer(fn(%{mailbox: [_, _]} = state) ->
      %{state | mailbox: []}
    end)
    |> Mailbox.send(:hello)
    |> Mailbox.send(:joe)
    |> State.receive()

    assert [] == state.mailbox

    State.cleanup(state)
  end
end
