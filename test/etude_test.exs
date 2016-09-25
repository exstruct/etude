defmodule Test.Etude do
  use Test.Etude.Case
  if Mix.env == :test do
    doctest Etude, import: true
  end
  import Etude

  bench "value", 100 do
    future = value(1)
    {
      fn ->
        1
      end,
      fn ->
        fork(future)
      end
    }
  end

  bench "map", 100 do
    future = value(1) |> map(&(&1 + 1)) |> map(&(&1 + 1)) |> map(&(&1 + 1))
    {
      fn ->
        v = 1
        v = v + 1
        v = v + 1
        v = v + 1
        v
      end,
      fn ->
        fork(future)
      end
    }
  end

  bench "async join", 50 do
    range = 1..100

    future = range
    |> Enum.map(fn(i) ->
      value_after(i, 0)
    end)
    |> join()

    {
      fn ->
        range
        |> Enum.map(fn(i) ->
          :erlang.send_after(0, self(), i)
          i
        end)
        |> Enum.map(fn(i) ->
          receive do
            ^i ->
              i
          end
        end)
      end,
      fn ->
        fork(future)
      end
    }
  end
end
