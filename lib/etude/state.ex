defmodule Etude.State do
  def __struct__ do
    %{__struct__: __MODULE__,
      cache: %{},
      mailbox: self(),
      mailbox_timeout: 10_000,
      private: %{},
      receivers: [],
      refs: %{},
      ref_default_timeout: 5_000,
      timeouts: %{},
    }
  end

  def receive(%{mailbox_timeout: timeout} = state) do
    state
    |> Etude.Mailbox.stream!(timeout)
    |> Enum.reduce(state, fn({message, mailbox}, state) ->
      Etude.Receivable.receive_into(message, %{state | mailbox: mailbox})
    end)
  end

  def add_receiver(%{receivers: receivers} = state, receiver) do
    %{state | receivers: [receiver | receivers]}
  end

  def put_private(%{private: private} = state, key, value) do
    %{state | private: Map.put(private, key, value)}
  end

  def cleanup(state) do
    state
    |> cancel_timeouts()
    |> demonitor_refs()
    |> Etude.Cache.clear()
  end

  defp cancel_timeouts(%{timeouts: timeouts} = state) do
    Enum.each(timeouts, fn({_key, timeout}) ->
      :timer.cancel(timeout)
    end)

    %{state | timeouts: %{}}
  end

  defp demonitor_refs(%{refs: refs} = state) do
    Enum.each(refs, fn({ref, _}) ->
      :erlang.demonitor(ref)
      ## TODO see if we can tell the process to stop processing the request
    end)

    %{state | refs: %{}}
  end
end

defimpl Etude.Cache, for: Etude.State do
  def get(%{cache: cache}, key) do
    Etude.Cache.get(cache, key)
  end

  def put(%{cache: cache} = state, key, value) do
    %{state | cache: Etude.Cache.put(cache, key, value)}
  end

  def memoize(%{cache: cache} = state, key, fun) do
    {value, cache} = Etude.Cache.memoize(cache, key, fun)
    {value, %{state | cache: cache}}
  end

  def delete(%{cache: cache} = state, key) do
    %{state | cache: Etude.Cache.delete(cache, key)}
  end

  def clear(%{cache: cache} = state) do
    %{state | cache: Etude.Cache.clear(cache)}
  end
end

defimpl Etude.Mailbox, for: Etude.State do
  def send(%{mailbox: mailbox} = state, message) do
    %{state | mailbox: Etude.Mailbox.send(mailbox, message)}
  end

  def stream!(%{mailbox: mailbox}, timeout) do
    mailbox
    |> Etude.Mailbox.stream!(timeout)
    ## TODO rescue any errors and wrap them so we can set the state in the exception
  end
end
