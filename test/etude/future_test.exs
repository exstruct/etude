defmodule Test.Etude.Future do
  use Test.Etude.Case

  import Etude.Future

  test "of" do
    of("Hello!")
    |> f()
    |> assert_term_match({:ok, "Hello!"})
  end

  test "reject" do
    reject("Error!")
    |> f()
    |> assert_term_match({:error, "Error!"})
  end

  test "send_after" do
    delay("Hello send_after", 100)
    |> f()
    |> assert_term_match({:ok, "Hello send_after"})
  end

  test "retry" do
    wrap(fn ->
      if :rand.uniform > 0.1 do
        throw :fail
      end
      :worked
    end)
    |> retry(:infinity)
    |> f()
    |> assert_term_match({:ok, :worked})
  end

  test "timeout_after" do
    delay("SHOULDN'T HAPPEN", 1000)
    |> timeout(10)
    |> retry(5)
    |> f()
    |> assert_term_match({:error, _})
  end

  test "encase" do
    args = ["{]"]
    encase(&Poison.decode!/1, args)
    |> f()
    |> assert_term_match({:error, _})
  end

  test "map success" do
    of(1)
    |> map(&(&1 + &1))
    |> f()
    |> assert_term_match({:ok, 2})
  end

  test "map fail" do
    reject(1)
    |> map(&(&1 + 2))
    |> f()
    |> assert_term_match({:error, 1})
  end

  test "map_rej" do
    reject(1)
    |> map_rej(&(&1 + 2))
    |> f()
    |> assert_term_match({:error, 3})
  end

  test "bimap success" do
    of(1)
    |> bimap(&(&1), &(&1 * 4))
    |> f()
    |> assert_term_match({:ok, 4})
  end

  test "bimap fail" do
    reject(2)
    |> bimap(&(trunc(&1 / 2)), &(&1))
    |> f()
    |> assert_term_match({:error, 1})
  end

  test "chain" do
    of("test")
    |> chain(fn(value) ->
      (value <> value)
      |> of()
    end)
    |> f()
    |> assert_term_match({:ok, "testtest"})
  end

  test "chain_rej" do
    reject("test")
    |> chain_rej(fn(value) ->
      (value <> value)
      |> of()
    end)
    |> f()
    |> assert_term_match({:ok, "testtest"})
  end

  test "swap success" do
    of(:swapped)
    |> swap()
    |> f()
    |> assert_term_match({:error, :swapped})
  end

  test "swap fail" do
    reject(:swapped)
    |> swap()
    |> f()
    |> assert_term_match({:ok, :swapped})
  end

  test "concat a" do
    a = delay(:first, 10)
    b = delay(:second, 20)
    concat(a, b)
    |> f()
    |> assert_term_match({:ok, :first})
  end

  test "concat b" do
    a = delay(:first, 20)
    b = delay(:second, 10)
    concat(a, b)
    |> f()
    |> assert_term_match({:ok, :second})
  end

  test "concat immediate a" do
    a = of(1)
    b = of(2)
    concat(a, b)
    |> f()
    |> assert_term_match({:ok, 1})
  end

  test "concat immediate b" do
    a = delay(1, 10)
    b = of(2)
    concat(a, b)
    |> f()
    |> assert_term_match({:ok, 2})
  end

  test "fold success" do
    of(1)
    |> fold(&(&1), &(&1 + 2))
    |> f()
    |> assert_term_match({:ok, 3})
  end

  test "fold fail" do
    reject(1)
    |> fold(&(&1 + 4), &(&1))
    |> f()
    |> assert_term_match({:ok, 5})
  end

  test "finally success" do
    assert_raise Etude.Future.Error, fn ->
      of(1)
      |> finally(
        of(1)
        |> map(fn(_) ->
          raise Etude.Future.Error
        end)
      )
      |> Etude.fork()
    end
  end

  test "finally fail" do
    assert_raise Etude.Future.Error, fn ->
      reject(1)
      |> finally(
        of(1)
        |> map(fn(_) ->
          raise Etude.Future.Error
        end)
      )
      |> Etude.fork()
    end
  end

  test "parallel success" do
    p_success(&parallel/1)
  end

  test "parallel concurrency success" do
    p_success(&parallel(&1, 2))
  end

  test "parallel disabled concurrency success" do
    p_success(&parallel(&1, 1))
  end

  test "parallel fail" do
    p_fail(&parallel(&1))
  end

  test "parallel concurrency fail" do
    p_fail(&parallel(&1, 2))
  end

  test "parallel disabled concurrency fail" do
    p_fail(&parallel(&1, 1))
  end

  test "pmap (+ 1 - 1)" do
    p_success(fn(l) ->
      l
      |> Enum.map(&(map(&1, fn(v) -> v + 1 end)))
      |> Enum.map(&(map(&1, fn(v) -> v - 1 end)))
      |> parallel()
    end)
  end

  test "cache" do
    future = encase(&:rand.uniform/1, [10]) |> cache()
    {:ok, [n | _] = list} = 1..20
    |> Enum.map(fn(_) -> future end)
    |> parallel()
    |> f()

    l = 1..20 |> Enum.map(fn(_) -> n end)
    assert l == list
  end

  defp p_success(fun) do
    for _ <- 1..5 do
      l = 1..(:rand.uniform(15) + 5)
      |> Enum.to_list()

      l
      |> Enum.map(fn(i) ->
        delay(i, :rand.uniform(20))
      end)
      |> fun.()
      |> f()
      |> assert_term_match({_, ^l})
    end
  end

  defp p_fail(fun) do
    for _ <- 1..5 do
      final = :rand.uniform(15)
      l = 1..(final + 5)
      |> Enum.to_list()

      l
      |> Enum.map(fn
        (i) when i == final ->
          reject(i)
        (i) ->
          delay(i, :rand.uniform(20))
      end)
      |> fun.()
      |> f()
      |> assert_term_match({:error, ^final})
    end
  end

  defp f(future) do
    fn ->
      Etude.fork(future)
    end
    |> Task.async()
    |> Task.await()
  end
end
