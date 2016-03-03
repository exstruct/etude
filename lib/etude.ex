defmodule Etude do
  @vsn Mix.Project.config[:version]

  def resolve(thunk) do
    resolve(thunk, [])
  end
  def resolve(thunk, opts) when is_list(opts) do
    {value, state} = resolve(thunk, %Etude.State{}, opts)
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
