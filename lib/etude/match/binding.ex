defmodule Etude.Match.Binding do
  defstruct [:name]
end

defimpl Etude.Matchable, for: Etude.Match.Binding do
  alias Etude.Match.{Executable,Utils}
  alias Etude.Future, as: F
  require F

  def compile(%{name: :_}) do
    %Executable{
      module: __MODULE__,
      function: :__execute_of__
    }
  end
  def compile(%{name: name}) do
    %Executable{
      module: __MODULE__,
      env: name
    }
  end

  def __execute__(name, v, b) do
    fn(state, rej, res) ->
      case Utils.fetch_binding(state, b, name) do
        :error ->
          state
          |> Utils.put_binding(b, name, v)
          |> res.(v)
        {:ok, ^v} ->
          res.(state, v)
        {:ok, binding} ->
          Etude.Unifiable.unify(binding, v, b)
          |> F.chain(fn(v) ->
            F.new(fn(state, _rej, res) ->
              state
              |> Utils.put_binding(b, name, v)
              |> res.(v)
            end)
          end)
          |> Etude.Forkable.fork(state, rej, res)
      end
    end
    |> F.new()
  end

  def __execute_of__(_, value, _) do
    F.of(value)
  end

  def compile_body(binding) do
    %Executable{
      module: __MODULE__,
      function: :__execute_body__,
      env: binding
    }
  end

  def __execute_body__(%{name: name} = binding, b) do
    fn(state, rej, res) ->
      case Utils.fetch_binding(state, b, name) do
        :error ->
          F.error(binding)
          |> Etude.Forkable.fork(state, rej, res)
        {:ok, value} ->
          res.(state, value)
      end
    end
    |> F.new()
  end
end
