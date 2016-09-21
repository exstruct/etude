defmodule Etude.Match.Utils do
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
end
