defmodule Etude.Match.Utils do
  alias Etude.Thunk

  def fetch_bindings(%{private: private}, binding_ref) do
    Map.get(private, binding_ref, %{})
  end

  def fetch_binding(state, binding_ref, name) do
    Map.fetch(fetch_bindings(state, binding_ref), name)
  end

  def put_binding(state, binding_ref, name, value) do
    bindings = fetch_bindings(state, binding_ref)
    Etude.State.put_private(state, binding_ref, Map.put(bindings, name, value))
  end

  def continuation(thunk, state, fun) do
    {:await, %Thunk.Continuation{
      arguments: [thunk],
      function: fn([h], state) ->
        Thunk.resolve(h, state, fun)
      end
    }, state}
  end

  def exec_patterns([], value, state, _) do
    {:ok, value, state}
  end
  def exec_patterns([pattern | patterns] = all, value, state, b) do
    case pattern.(value, state, b) do
      {:ok, value, state} ->
        exec_patterns(patterns, value, state, b)
      {:await, thunk, state} ->
        ## TODO OPTIMIZE keep going here
        continuation(thunk, state, (&exec_patterns(all, &1, &2, b)))
      {:error, state} ->
        {:error, state}
    end
  end
end
