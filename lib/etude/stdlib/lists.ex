defmodule Etude.STDLIB.Lists do
  alias Etude.Future, as: F

  def reverse(list) do
    reverse(list, [])
  end

  defp reverse([], acc) do
    F.of(acc)
  end
  defp reverse([head | tail], acc) do
    reverse(tail, [head | acc])
  end
  defp reverse(list, acc) do
    list
    |> F.to_term()
    |> F.chain(fn
      ([]) ->
        F.of(acc)
      ([head | tail]) ->
        reverse(tail, [head | acc])
      (other) ->
        F.error(%CaseClauseError{term: other})
    end)
  end
end
