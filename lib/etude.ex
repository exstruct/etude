defmodule Etude do
  @vsn Mix.Project.config[:version]

  def resolve(thunk) do
    {value, state} = resolve(thunk, %Etude.State{})
    Etude.State.cleanup(state)
    value
  end

  def resolve(thunk, state) do
    case Etude.Thunk.resolve(thunk, state) do
      {value, state} ->
        {value, state}
      {:await, thunk, state} ->
        state = Etude.State.mailbox_receive(state)
        resolve(thunk, state)
    end
  end
end
