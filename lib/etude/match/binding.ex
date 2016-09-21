defmodule Etude.Match.Binding do
  defstruct [:name]
end

defimpl Etude.Matchable, for: Etude.Match.Binding do
  alias Etude.Match.Utils
  require Etude.Future

  def compile(%{name: :_}) do
    fn(value, _b) ->
      Etude.Future.of(value)
    end
  end
  def compile(%{name: name}) do
    fn(v, b) ->
      fn(state, rej, res) ->
        case Utils.fetch_binding(state, b, name) do
          :error ->
            state
            |> Utils.put_binding(b, name, v)
            |> res.(v)
          {:ok, ^v} ->
            res.(state, v)
          {:ok, binding} ->
            Etude.Unifiable.unify(binding, v)
            |> Etude.Future.chain(fn(v) ->
              Etude.Future.new(fn(state, _rej, res) ->
                state
                |> Utils.put_binding(b, name, v)
                |> res.(v)
              end)
            end)
            |> Etude.Forkable.fork(state, rej, res)
        end
      end
      |> Etude.Future.new()
    end
  end

  def compile_body(%{name: name} = binding) do
    fn(b) ->
      fn(state, rej, res) ->
        case Utils.fetch_binding(state, b, name) do
          :error ->
            rej.(state, binding)
          {:ok, value} ->
            res.(state, value)
        end
      end
      |> Etude.Future.new()
    end
  end
end
