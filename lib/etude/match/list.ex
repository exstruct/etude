defimpl Etude.Matchable, for: List do
  alias Etude.Match.{Error,Executable,Literal}

  def compile([]) do
    Literal.compile([])
  end
  def compile(l) do
    l_f = c(l, [], :compile)
    %Executable{
      module: __MODULE__,
      env: l_f
    }
  end

  def __execute__(l_f, v, b) do
    v
    |> Etude.Future.to_term()
    |> Etude.Future.chain(fn
      (v) when is_list(v) ->
        compare(l_f, v, b, [])
      (v) ->
        Etude.Future.error(%Error{term: v, binding: b})
    end)
  end

  defp compare([], [], _, acc) do
    acc
    |> :lists.reverse()
    |> Etude.Future.parallel()
  end
  defp compare([a_h | a_t], [b_h | b_t], b, acc) do
    f = Executable.execute(a_h, b_h, b)
    compare(a_t, b_t, b, [f | acc])
  end
  defp compare(%Executable{} = a, b, bindings, acc) do
    f = Executable.execute(a, b, bindings)
    compare([], [], bindings, [f | acc])
  end
  defp compare(_, b, binding, _acc) do
    Etude.Future.error(%Error{term: b, binding: binding})
  end

  def compile_body([]) do
    Literal.compile_body([])
  end
  def compile_body(l) do
    l = c(l, [], :compile_body)
    %Executable{
      module: __MODULE__,
      function: :__execute_body__,
      env: l
    }
  end

  def __execute_body__(l, b) do
    Enum.map(l, &Executable.execute(&1, b))
  end

  defp c([], acc, _fun) do
    :lists.reverse(acc)
  end
  defp c([head | tail], acc, fun) do
    h = apply(@protocol, fun, [head])
    c(tail, [h | acc], fun)
  end
  defp c(tail, acc, fun) do
    t = apply(@protocol, fun, [tail])
    reverse_cons(acc, t)
  end

  defp reverse_cons([], acc) do
    acc
  end
  defp reverse_cons([head | tail], acc) do
    reverse_cons(tail, [head | acc])
  end
end
