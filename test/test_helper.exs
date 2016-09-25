defmodule Test.Etude.Case do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: Mix.env == :test
      import unquote(__MODULE__)
      import Fugue.Assertions

      setup do
        :rand.seed(:exs1024, {ExUnit.configuration()[:seed], 0, 0})
        :ok
      end
    end
  end

  defmacro bench(name, count, [do: body]) do
    quote do
      if Mix.env == :bench do
        test "benchmark #{unquote(name)}" do
          {a, b} = unquote(body)
          # warm it
          a.()
          b.()
          count = unquote(count)
          a = Test.Etude.Case.__bench__("control", a, count)
          b = Test.Etude.Case.__bench__("subject", b, count)
          try do
            IO.puts "\n"
            :eministat.x(95.0, a, b)
          rescue
            FunctionClauseError ->
              IO.puts "no difference"
          end
        end
      end
    end
  end

  def __bench__(name, fun, count) do
    warm(fun, 0)
    :eministat_ds.from_list(name, measure(fun, count, []))
  end

  defp warm(_, time) when time >= 2_000_000 do
    :ok
  end
  defp warm(fun, time) do
    case :timer.tc(fun) do
      {0, _} ->
        warm(fun, time + 1)
      {t, _} ->
        warm(fun, time + t)
    end
  end

  defp measure(_, 0, acc) do
    :lists.reverse(acc)
  end
  defp measure(fun, count, acc) do
    :erlang.garbage_collect()
    {t, _} = :timer.tc(fun)
    measure(fun, count - 1, [t | acc])
  end
end

seed = ExUnit.configuration()[:seed] || :erlang.phash2(:crypto.rand_bytes(20))
ExUnit.start([seed: seed])
