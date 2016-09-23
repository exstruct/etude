defmodule Etude.Match.Binary do
  defstruct [:fun]
end

defimpl Etude.Matchable, for: Etude.Match.Binary do
  alias Etude.Match.Executable

  def compile(%{fun: fun}) do
    %Executable{
      module: __MODULE__,
      env: fun
    }
  end

  def __execute__(fun, value, b) do
    value
    |> Etude.Future.to_term()
    |> Etude.Future.chain(fn
      (bin) when is_binary(bin) ->
        fun
        |> Etude.Future.encase([bin])
        |> Etude.Future.chain(fn
          (bindings) when map_size(bindings) == 0 ->
            Etude.Future.of(bin)
          (bindings) ->
            bindings
            |> Enum.map(fn({k, v}) ->
              %Etude.Match.Binding{name: k}
              |> @protocol.compile()
              |> Executable.execute(v, b)
            end)
            |> Etude.Future.parallel()
            |> Etude.Future.map(fn(_) -> bin end)
        end)
        |> Etude.Future.chain_rej(fn(_) ->
          Etude.Future.reject(%MatchError{term: bin})
        end)
      (other) ->
        Etude.Future.reject(%MatchError{term: other})
    end)
  end

  def compile_body(body) do
    throw {:invalid_body, body}
  end
end
