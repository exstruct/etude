defprotocol Etude.Forkable do
  @fallback_to_any true
  def fork(future, state, stack)
end

defimpl Etude.Forkable, for: Task do
  alias Etude.{Receiver,State}

  def fork(%{ref: ref} = task, state, _) do
    receiver = %Receiver{
      handle_info: fn
        (_, {^ref, reply}, state) ->
          Process.demonitor(ref, [:flush])
          {:ok, reply, state}
        (_, {:DOWN, ^ref, _, proc, :noconnection}, state) ->
          {:error, {:noconnection, proc}, state}
        (_, {:DOWN, ^ref, _, _, reason}, state) ->
          {:error, reason, state}
        (_, _, _) ->
          :pass
      end,
      cancel: fn(_, state) ->
        _ = Task.shutdown(task, :brutal_kill)
        state
      end
    }

    {register, state} = State.create_receiver(state, receiver, nil)

    {:await, register, state}
  end
end

defimpl Etude.Forkable, for: Any do
  def fork(value, state, _) do
    {:ok, value, state}
  end
end
