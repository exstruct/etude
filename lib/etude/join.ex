defmodule Etude.Join do
  @moduledoc false
  import Etude.Macros
  alias Etude.{State}

  deffuture join(futures, concurrency) do
    Etude.Join.__join__(futures, %{}, 0, 0, concurrency, state, nil, stack)
  end

  def __join__([], acc, 0, _, _, state, observer, _stack) do
    state = maybe_cleanup(state, observer)
    acc = acc
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
    {:ok, acc, state}
  end
  def __join__(futures, acc, pending, index, concurrency, state, observer, stack) when futures == [] or pending >= concurrency do
    context = {futures, acc, pending, index, concurrency, stack}
    state = State.put_context(state, observer, context)
    {:await, observer, state}
  end
  def __join__([future | futures], acc, pending, index, concurrency, state, observer, stack) do
    f(future, state, fn(value, state) ->
      acc = Map.put(acc, index, value)
      __join__(futures, acc, pending, index + 1, concurrency, state, observer, stack)
    end, fn(error, state) ->
      state = maybe_cleanup(state, observer)
      {:error, error, state}
    end, fn(register, state) ->
      {observer, state} = observe(state, observer, register, index)
      __join__(futures, acc, pending + 1, index + 1, concurrency, state, observer, stack)
    end)
  end

  defp maybe_cleanup(state, nil) do
    state
  end
  defp maybe_cleanup(state, observer) do
    State.cleanup(state, observer)
  end

  defp observe(state, nil, pending, id) do
    {observer, state} = State.create_observer(state, &__MODULE__.__observer__/6)
    observe(state, observer, pending, id)
  end
  defp observe(state, observer, pending, id) do
    {observer, State.link(state, pending, observer, id)}
  end

  def __observer__(id, {futures, acc, pending, index, concurrency, stack}, key, :ok, value, state) do
    acc = Map.put(acc, key, value)
    __join__(futures, acc, pending - 1, index, concurrency, state, id, stack)
  end
  def __observer__(_id, _context, _ref, :error, error, state) do
    {:error, error, state}
  end
end
