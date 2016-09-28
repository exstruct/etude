defmodule Etude.Select do
  @moduledoc false

  import Etude.Macros
  alias Etude.{State}

  deffuture select(futures, count) do
    Etude.Select.__select__(futures, [], 0, count, state, nil, stack)
  end

  def __select__([], acc, size, count, state, observer, _stack) do
    context = {acc, size, count}
    state = State.put_context(state, observer, context)
    {:await, observer, state}
  end
  def __select__(_, acc, size, count, state, observer, _stack) when size == count do
    state = maybe_cleanup(state, observer)
    {:ok, :lists.reverse(acc), state}
  end
  def __select__([future | futures], acc, size, count, state, observer, stack) do
    f(future, state, fn(value, state) ->
      __select__(futures, [value | acc], size + 1, count, state, observer, stack)
    end, fn(error, state) ->
      state = maybe_cleanup(state, observer)
      {:error, error, state}
    end, fn(register, state) ->
      {observer, state} = observe(state, observer, register)
      __select__(futures, acc, size, count, state, observer, stack)
    end)
  end

  defp maybe_cleanup(state, nil) do
    state
  end
  defp maybe_cleanup(state, observer) do
    State.cleanup(state, observer)
  end

  defp observe(state, nil, pending) do
    {observer, state} = State.create_observer(state, &__MODULE__.__observer__/6)
    observe(state, observer, pending)
  end
  defp observe(state, observer, pending) do
    {observer, State.link(state, pending, observer)}
  end

  def __observer__(_id, {acc, size, count}, _ref, :ok, value, state) when (size + 1 == count) do
    {:ok, :lists.reverse([value | acc]), state}
  end
  def __observer__(id, {acc, size, count}, _ref, :ok, value, state) do
    context = {[value | acc], size + 1, count}
    state = State.put_context(state, id, context)
    {:await, id, state}
  end
  def __observer__(_id, _context, _ref, :error, error, state) do
    {:error, error, state}
  end
end
