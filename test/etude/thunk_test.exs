defmodule Test.Etude.Thunk do
  use Test.Etude.Case

  test "resolve single continuation" do
    [resolve_value(1),
     resolve_value(2),
     resolve_value(3)]
    |> resolve(fn(a, s) ->
      {:foo, a}
      |> done(s)
    end)
    |> assert_resolve(%{})
    |> assert_value({:foo, [1,2,3]})
  end

  test "resolve awaited continuation" do
    [resolve_value(1),
     resolve_value(2),
     resolve_value(3)]
    |> await(fn(a, s) ->
      {:bar, a}
      |> done(s)
    end)
    |> into(fn({:bar, [first | _]}, s) ->
      first
      |> done(s)
    end)
    |> assert_resolve(%{})
    |> assert_await()
    |> assert_value(1)
  end

  test "call a native function" do
    [await_value(1),
     resolve_value(2)]
    |> resolve_apply(:erlang, :+)
    |> assert_resolve(%{})
    |> assert_await()
    |> assert_value(3)
  end

  test "anonymous functions" do
    [1..5]
    |> resolve(fn([range], _s) ->
      Enum.map(range, fn(_i) ->
        nil
      end)
    end)
  end

  defp into(thunk, fun) do
    [thunk]
    |> resolve(fn([t], s) ->
      fun.(t, s)
    end)
  end

  defp await_apply(arguments, module, function) do
    await(arguments, fn(args, s) ->
      {apply(module, function, args), s}
    end)
  end

  defp await_value(value) do
    await(fn(s) -> {value, s} end)
  end

  defp await(fun) do
    await([], fn(_, s) ->
      fun.(s)
    end)
  end

  defp await(arguments, fun) do
    arguments
    |> c(fn(args, state) ->
      {:await, resolve(args, fun), state}
    end)
  end

  def resolve_value(value) do
    resolve(fn(s) -> {value, s} end)
  end

  defp resolve_apply(arguments, module, function) do
    resolve(arguments, fn(args, s) ->
      {apply(module, function, args), s}
    end)
  end

  defp resolve(fun) do
    resolve([], fn(_, s) ->
      fun.(s)
    end)
  end

  defp resolve(arguments, fun) do
    arguments
    |> c(fn(args, state) ->
      resolve_all(args, state, fun)
    end)
  end

  defp done(value, state) do
    {value, state}
  end

  defp c(arguments, fun) do
    %Etude.Thunk.Continuation{function: fun, arguments: arguments}
  end

  defp resolve_all(thunks, state, fun) do
    Etude.Thunk.resolve_all(thunks, state, fun)
  end

  defp assert_resolve({value, state}) do
    Etude.Thunk.resolve(value, state)
  end
  defp assert_resolve({value, state}, fun) do
    Etude.Thunk.resolve(value, state, fun)
  end

  defp assert_resolve(thunk, state) do
    Etude.Thunk.resolve(thunk, state)
  end
  defp assert_resolve(thunk, state, fun) do
    Etude.Thunk.resolve(thunk, state, fun)
  end

  defp assert_await({:await, thunk, state}) do
    Etude.Thunk.resolve(thunk, state)
  end
  defp assert_await({:await, thunk, state}, fun) do
    Etude.Thunk.resolve(thunk, state, fun)
  end

  defp assert_value({actual, state}, expected) do
    assert actual == expected
    {actual, state}
  end
end
