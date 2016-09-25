defmodule Etude.Timer do
  alias Etude.{Receiver,State}

  def call_after(fun, time, state) do
    ref = :erlang.unique_integer()
    timer = :erlang.send_after(time, self(), ref)

    receiver = %Receiver{
      handle_info: fn
        (_, ^ref, state) ->
          fun.(state)
        (_, _, _) ->
          :pass
      end,
      cancel: fn(_, state) ->
        :erlang.cancel_timer(timer)
        state
      end
    }

    {register, state} = State.create_receiver(state, receiver, nil)

    {:await, register, state}
  end
end
