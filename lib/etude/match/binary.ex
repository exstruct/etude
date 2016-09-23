defmodule Etude.Match.Binary do
  defstruct [:fun]
end

defimpl Etude.Matchable, for: Etude.Match.Binary do
  alias Etude.Future, as: F
  alias Etude.Match.Error
  alias Etude.Match.Executable

  def compile(%{fun: fun}) do
    %Executable{
      module: __MODULE__,
      env: fun
    }
  end

  def __execute__(fun, value, b) do
    value
    |> F.to_term()
    |> F.chain(fn
      (bin) when is_binary(bin) ->
        fun
        |> F.encase([bin])
        |> F.chain(fn
          (bindings) when map_size(bindings) == 0 ->
            F.of(bin)
          (bindings) ->
            bindings
            |> Enum.map(fn({k, v}) ->
              %Etude.Match.Binding{name: k}
              |> @protocol.compile()
              |> Executable.execute(v, b)
            end)
            |> F.parallel()
            |> F.map(fn(_) -> bin end)
        end)
        |> F.chain_rej(fn(_) ->
          F.error(%Error{term: bin, binding: b})
        end)
      (other) ->
        F.error(%Error{term: other, binding: b})
    end)
  end

  def compile_body(body) do
    throw {:invalid_body, body}
  end
end
