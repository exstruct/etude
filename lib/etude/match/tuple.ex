defimpl Etude.Matchable, for: Tuple do
  alias Etude.Match.Executable

  def compile({}) do
    Etude.Match.Literal.compile({})
  end
  def compile(tuple) do
    patterns = :erlang.tuple_to_list(tuple) |> Enum.map(&@protocol.compile/1)
    size = tuple_size(tuple)

    %Executable{
      module: __MODULE__,
      env: {patterns, size}
    }
  end

  def __execute__({patterns, size}, v, b) do
    v
    |> Etude.Future.to_term()
    |> Etude.Future.chain(fn
      (v) when is_tuple(v) and tuple_size(v) == size ->
        compare(patterns, v, b, 0, [])
      (v) ->
        Etude.Future.reject(%MatchError{term: v})
    end)
  end

  defp compare([], _, _, _, acc) do
    acc
    |> :lists.reverse()
    |> Etude.Future.parallel()
    |> Etude.Future.map(&:erlang.list_to_tuple/1)
  end
  defp compare([pattern | patterns], subject, b, idx, acc) do
    value = elem(subject, idx)
    future = Executable.execute(pattern, value, b)
    compare(patterns, subject, b, idx + 1, [future | acc])
  end

  def compile_body(tuple) do
    bodies = :erlang.tuple_to_list(tuple) |> Enum.map(&@protocol.compile_body/1)

    %Executable{
      module: __MODULE__,
      function: :__execute_body__,
      env: bodies
    }
  end

  def __execute_body__(bodies, b) do
    bodies
    |> Enum.map(&Executable.execute(&1, b))
    |> :erlang.list_to_tuple()
  end
end
