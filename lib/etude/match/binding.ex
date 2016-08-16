defmodule Etude.Match.Binding do
  defstruct [:name]

  defimpl Etude.Matchable do
    alias Etude.Match.Utils

    def compile(%{name: :_}) do
      fn(value, state, _b) ->
        {:ok, value, state}
      end
    end
    def compile(%{name: name}) do
      fn(value, state, b) ->
        case Utils.fetch_binding(state, b, name) do
          :error ->
            {:ok, value, Utils.put_binding(state, b, name, value)}
          {:ok, ^value} ->
            {:ok, value, state}
          {:ok, binding} ->
            Etude.Thunk.resolve_all([value, binding], state, fn
              ([v, v], state) ->
                {:ok, v, Utils.put_binding(state, b, name, v)}
              ([_, _], state) ->
                {:error, state}
            end)
        end
      end
    end

    def compile_body(%{name: name}) do
      fn(state, b) ->
        case Utils.fetch_binding(state, b, name) do
          :error ->
            {:error, state}
          {:ok, value} ->
            {:ok, value, state}
        end
      end
    end
  end
end
