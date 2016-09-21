defmodule Etude.Match.Binary do
  defstruct [:fun]
end

defimpl Etude.Matchable, for: Etude.Match.Binary do
  def compile(%{fun: fun}) do
    fn(value, b) ->
      value
      |> Etude.Future.to_term()
      |> Etude.Future.chain(fn
        (bin) when is_binary(bin) ->
          Etude.Future.encase(fun, [bin])
          |> Etude.Future.chain(fn
            (bindings) when map_size(bindings) == 0 ->
              Etude.Future.of(bin)
            (bindings) ->
              bindings
              |> Enum.map(fn({k, v}) ->
                binding = %Etude.Match.Binding{name: k}
                @protocol.compile(binding).(v, b)
              end)
              |> Etude.Future.parallel()
              |> Etude.Future.map(fn(_) -> bin end)
          end)
          |> Etude.Future.chain_rej(fn(_) ->
            Etude.Future.reject({bin, :bad_match})
          end)
        (other) ->
          Etude.Future.reject({other, :expected_binary})
      end)
    end
  end

  def compile_body(body) do
    throw {:invalid_body, body}
  end
end
