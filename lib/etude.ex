defmodule Etude do
  @vsn Mix.Project.config[:version]
  alias Etude.{Future,State}

  def fork(future) do
    {type, value, state} = fork(future, %State{mailbox: self()})
    State.cleanup(state)
    {type, value}
  end

  def fork!(future) do
    case fork(future) do
      {:ok, value} ->
        value
      {:error, error} ->
        handle_error(error)
    end
  end

  def fork(future, state) do
    {ref, state, _cancel} = Future.fork(future, state)
    await(state, ref)
  end

  def fork!(future, state) do
    case fork(future, state) do
      {:ok, value, state} ->
        {value, state}
      {:error, error, state} ->
        State.cleanup(state)
        handle_error(error)
    end
  end

  defp handle_error(error) do
    case error do
      %Future.Error{payload: %{__exception__: true} = error, stacktrace: stack} ->
        reraise error, stack
      %Future.Error{payload: error, stacktrace: stack} ->
        :erlang.raise(:throw, error, stack)
      %{__exception__: true} ->
        raise error
      error ->
        throw error
    end
  end

  defp await(state, ref) do
    case Future.await(state, ref) do
      :cont ->
        state
        |> State.receive()
        |> State.execute()
        |> await(ref)
      {type, value} ->
        {type, value, state}
    end
  end
end
