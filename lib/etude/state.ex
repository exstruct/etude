defmodule Etude.State do
  defstruct cache: %{},
            mailbox: [],
            mailbox_timeout: 10_000,
            private: %{},
            reducers: [],
            receivers: [],
            refs: %{},
            ref_default_timeout: 5_000,
            timeouts: %{},
            unhandled_warning: true

  defmodule TimeoutException do
    defexception [:message, :state]
  end

  def receive(%{reducers: [], mailbox_timeout: timeout} = state) do
    state
    |> Etude.Mailbox.stream!(timeout)
    |> Enum.reduce(state, fn({message, mailbox}, state) ->
      Etude.Receivable.receive_into(message, %{state | mailbox: mailbox})
    end)
  end
  def receive(%{reducers: [prepare | rest]} = state) do
    __MODULE__.receive(%{prepare.(state) | reducers: rest})
  end

  def add_receiver(%{receivers: receivers} = state, receiver) do
    %{state | receivers: [receiver | receivers]}
  end

  def add_reducer(%{reducers: reducers} = state, prepare) do
    %{state | reducers: [prepare | reducers]}
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
    case Etude.Cache.memoize(cache, key, fun) do
      {:ok, value, cache} ->
        {:ok, value, %{state | cache: cache}}
    end
  end

  def delete(%{cache: cache} = state, key) do
    %{state | cache: Etude.Cache.delete(cache, key)}
  end

  def clear(%{cache: cache} = state) do
    %{state | cache: Etude.Cache.clear(cache)}
  end
end

defimpl Etude.Mailbox, for: Etude.State do
  alias Etude.State.TimeoutException
  def send(%{mailbox: mailbox} = state, message) do
    %{state | mailbox: Etude.Mailbox.send(mailbox, message)}
  end

  def stream!(%{mailbox: mailbox} = state, timeout) do
    mailbox
    |> Etude.Mailbox.stream!(timeout)
    |> Nile.Exception.rescue_stream(Etude.Mailbox.TimeoutException, fn
      (%{mailbox: nil} = e) ->
        message = Etude.Mailbox.TimeoutException.message(e)
        stacktrace = System.stacktrace
        reraise %TimeoutException{message: message, state: state}, stacktrace
      (%{mailbox: mailbox} = e) ->
        message = Etude.Mailbox.TimeoutException.message(e)
        stacktrace = System.stacktrace
        reraise %TimeoutException{message: message, state: %{state | mailbox: mailbox}}, stacktrace
    end)
  end
end
