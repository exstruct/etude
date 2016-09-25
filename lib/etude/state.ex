defmodule Etude.State do
  defstruct [contexts: %{},
             links: %{},
             observers: %{},
             receivers: %{},
             values: [],]

  require Logger

  @doc """

  """
  def create_receiver(%{receivers: receivers, contexts: contexts} = state, receiver, init \\ nil) do
    ref = :erlang.unique_integer()
    state = %{state | receivers: Map.put(receivers, ref, receiver),
                      contexts: Map.put(contexts, ref, init)}
    {ref, state}
  end

  @doc """

  """
  def create_observer(%{observers: observers, contexts: contexts} = state, observer, init \\ nil) do
    ref = :erlang.unique_integer()
    state = %{state | observers: Map.put(observers, ref, observer),
                      contexts: Map.put(contexts, ref, init)}
    {ref, state}
  end

  @doc """

  """
  def link(%{links: links} = state, source, targets) when is_list(targets) do
    targets = :lists.reverse(targets)
    case Map.fetch(links, source) do
      :error ->
        %{state | links: Map.put(links, source, targets)}
      {:ok, l} ->
        %{state | links: Map.put(links, source, targets ++ l)}
    end
  end
  def link(%{links: links} = state, source, target) when is_function(target) do
    case Map.fetch(links, source) do
      :error ->
        %{state | links: Map.put(links, source, [target])}
      {:ok, l} ->
        %{state | links: Map.put(links, source, [target | l])}
    end
  end
  def link(state, source, target) do
    link(state, source, target, source)
  end

  @doc """

  """
  def link(%{links: links} = state, source, target, ref) do
    case Map.fetch(links, source) do
      :error ->
        %{state | links: Map.put(links, source, [{target, ref}])}
      {:ok, l} ->
        %{state | links: Map.put(links, source, [{target, ref} | l])}
    end
  end

  @doc """

  """
  def put_context(%{contexts: contexts} = state, ref, context) do
    %{state | contexts: Map.put(contexts, ref, context)}
  end

  @doc """

  """
  def cancel(%{observers: observers, receivers: receivers, contexts: contexts} = state, ref) do
    # TODO cleanup all of the ref links
    case Map.pop(receivers, ref) do
      {%{cancel: cancel}, receivers} ->
        {context, contexts} = Map.pop(contexts, ref)
        state = %{state | contexts: contexts, receivers: receivers}
        cancel.(context, state)
      {nil, _} ->
        observers = Map.delete(observers, ref)
        contexts = Map.delete(contexts, ref)
        %{state | contexts: contexts, observers: observers}
    end
  end

  @doc """

  """
  def cleanup(%{receivers: receivers} = state) do
    # This should usually be empty
    Enum.reduce(receivers, state, fn({ref, _}, state) -> cleanup(state, ref) end)
  end

  @doc """

  """
  # TODO improve this thang
  def cleanup(%{links: links} = state, refs) when is_list(refs) do
    Enum.reduce(links, state, fn({source, targets}, state) ->
      linked = Enum.any?(targets, fn
        ({ref, _}) -> ref in refs
        (t) -> t in refs
      end)

      if linked do
        [source | targets]
        |> Enum.reduce(state, fn
          ({ref, _}, state) ->
            cancel(state, ref)
          (ref, state) ->
            cancel(state, ref)
        end)
      else
        state
      end
    end)
  end
  def cleanup(state, ref) do
    cleanup(state, [ref])
  end

  @doc """

  """
  def await(state) do
    state = prepare(state)
    state = Etude.Mailbox.receive_into(state)
    case trigger(state) do
      {status, value, state} ->
        {status, value, state}
      %__MODULE__{} = state ->
        await(state)
    end
  end

  @doc """

  """
  def await(state, target) do
    state
    |> link(target, fn(status, value, state) ->
      throw {:done, {status, value, state}}
    end)
    |> await()
  catch
    :throw, {:done, result} ->
      result
  end

  defp prepare(state) do
    # TODO
    state
  end

  @doc """

  """
  def handle_info(%{contexts: contexts, receivers: receivers} = state, message) do
    {contexts, receivers, state} =
      :maps.fold(fn(ref, %{handle_info: fun}, {contexts, receivers, state}) ->
        {:ok, context} = Map.fetch(contexts, ref)
        case fun.(context, message, state) do
          :pass ->
            {contexts, receivers, state}
          {:cont, context, state} ->
            contexts = Map.put(contexts, ref, context)
            state = %{state | contexts: contexts}
            throw {:done, state}
          {status, value, %{values: values} = state} when status in [:ok, :error] ->
            values = [{ref, status, value} | values]
            contexts = Map.delete(contexts, ref)
            receivers = Map.delete(receivers, ref)
            state = %{state | values: values, contexts: contexts, receivers: receivers}
            throw {:done, state}
        end
      end, {contexts, receivers, state}, receivers)

    Logger.warn("Unhandled message #{inspect(message)} in #{inspect(self())}")

    %{state | contexts: contexts, receivers: receivers}
  catch
    :throw, {:done, state} ->
      state
  end

  @doc """

  """
  def trigger(%{values: []} = state) do
    state
  end
  def trigger(%{values: values} = state) do
    state = %{state | values: []}
    values
    |> :lists.reverse()
    |> Enum.reduce(state, fn({ref, status, value}, %{links: links} = state) ->
      case Map.pop(links, ref) do
        {nil, _} ->
          state
        {l, links} ->
          state = %{state | links: links}

          l
          |> :lists.reverse()
          |> observe(ref, status, value, state)
      end
    end)
    |> trigger()
  end

  defp observe([], ref, status, value, %{values: values} = state) do
    %{state | values: [{ref, status, value} | values]}
  end
  defp observe([observer | observers], ref, status, value, state) when is_function(observer) do
    case observer.(status, value, state) do
      {status, value, state} when status in [:ok, :error] ->
        observe(observers, ref, status, value, state)
      {:await, new_ref, state} ->
        link(state, new_ref, observers)
    end
  end
  defp observe([observer | observers], ref, status, value, state) do
    {fun, observer_ref, context, link_ref} = fetch_observer(state, observer, ref)
    case fun.(observer_ref, context, link_ref, status, value, state) do
      {status, value, state} when status in [:ok, :error] ->
        state = cleanup(state, observer_ref)
        observe(observers, observer_ref, status, value, state)
      {:await, new_ref, state} ->
        link(state, new_ref, observers)
    end
  end

  defp fetch_observer(state, {observer, link_id}, _ref) do
    fetch_observer(state, observer, link_id)
  end
  defp fetch_observer(%{contexts: contexts, observers: observers}, observer, link_id) do
    {:ok, fun} = Map.fetch(observers, observer)
    {:ok, context} = Map.fetch(contexts, observer)
    {fun, observer, context, link_id}
  end
end
