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

  def cache_get(%{cache: cache}, key) do
    Etude.Cache.get(cache, key)
  end

  def cache_put(%{cache: cache} = state, key, value) do
    %{state | cache: Etude.Cache.put(cache, key, value)}
  end

  def cache_put_new_lazy(%{cache: cache} = state, key, fun) do
    {_, cache} = Etude.Cache.put_new_lazy_and_return(cache, key, fun)
    %{state | cache: cache}
  end

  def memoize(%{cache: cache} = state, key, fun) do
    {value, cache} = Etude.Cache.put_new_lazy_and_return(cache, key, fun)
    {value, %{state | cache: cache}}
  end

  def send(%{mailbox: mailbox} = state, message) do
    %{state | mailbox: Etude.Mailbox.send(mailbox, message)}
  end

  def receive(%{mailbox: mailbox, mailbox_timeout: timeout} = state) do
    mailbox
    |> Etude.Mailbox.stream!(timeout)
    ## TODO resuce any errors and wrap them so we can set the state in the exception
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
    |> clear_cache()
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

  defp clear_cache(%{cache: cache} = state) do
    %{state | cache: Etude.Cache.clear(cache)}
  end
end
