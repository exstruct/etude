defmodule Etude do
  @vsn Mix.Project.config[:version]
  alias Etude.State

  def fork(future) do
    {type, value, state} = fork(future, %State{mailbox: self()})
    State.cleanup(state)
    {type, value}
  end

  def fork(future, state) do
    {ref, state, _cancel} = Etude.Future.fork(future, state)
    await(state, ref)
  end

  defp await(state, ref) do
    case Etude.Future.await(state, ref) do
      :cont ->
        state
        |> State.receive()
        |> State.execute()
        |> await(ref)
      {type, value} ->
        {type, value, state}
    end
  end

  def resolve(thunk) do
    resolve(thunk, [])
  end
  def resolve(thunk, opts) when is_list(opts) do
    {:ok, value, state} = resolve(thunk, %Etude.State{mailbox: self()}, opts)
    Etude.State.cleanup(state)
    value
  end
  def resolve(thunk, state) do
    resolve(thunk, state, [])
  end
  def resolve(thunk, state, opts) do
    Etude.Serializer.TERM.serialize(thunk, state, opts)
  end
end
