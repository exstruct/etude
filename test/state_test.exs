defmodule Test.Etude.State do
  use Test.Etude.Case
  alias Etude.{State,Receiver}

  test "observer" do
    state = %State{}

    receiver = %Receiver{
      handle_info: fn
        (_context, :hello, state) ->
          {:ok, "Hello", state}
        (_, _, _) ->
          :pass
      end,
      cancel: fn(_context, state) ->
        state
      end
    }

    {register, state} = State.create_receiver(state, receiver)

    state = State.link(state, register, fn(:ok, value, state) ->
      {:ok, value <> ", Joe", state}
    end)

    state = State.link(state, register, fn(:ok, value, state) ->
      {:ok, value <> "!", state}
    end)

    send(self, :hello)

    assert {:ok, "Hello, Joe!", _} = State.await(state, register)
  end
end
