defmodule Etude do
  @moduledoc """
  Etude is a futures library for Elixir/Erlang.
  """

  @vsn Mix.Project.config[:version]
  alias Etude.{Forkable,State}
  import Etude.Macros

  @doc """
  Start execution of a future with the default `%Etude.State{}`

  See fork/2
  """

  def fork(future) do
    case fork(future, %State{}) do
      {:ok, value, state} ->
        State.cleanup(state)
        {:ok, value}
      {:error, error, state} ->
        State.cleanup(state)
        {:error, error}
    end
  end

  @doc """
  Start execution of a future while raising any errors

  See fork/2
  """

  def fork!(future) do
    case fork(future) do
      {:ok, value} ->
        value
      {:error, %{__exception__: true} = error} ->
        raise error
      {:error, error} ->
        throw error
    end
  end

  @doc """
  Start execution of a future
  """

  def fork(future, state) do
    case Forkable.fork(future, state, []) do
      {:ok, value, state} ->
        {:ok, value, state}
      {:error, error, state} ->
        {:error, error, state}
      {:await, register, state} ->
        State.await(state, register)
    end
  end

  @doc """
  Wrap a success value in a future.

      iex> 1 |> ok() |> fork!()
      1

      iex> %{hello: "Joe"} |> ok() |> fork!()
      %{hello: "Joe"}
  """

  @spec ok(any) :: Etude.Ok.t
  deffuture ok(value) do
    {:ok, value, state}
  end

  @doc """
  Wrap an error in a future.

      iex> 1 |> error() |> fork()
      {:error, 1}

      iex> %{uh: :oh} |> error() |> fork()
      {:error, %{uh: :oh}}
  """

  @spec error(any) :: Forkable.t
  deffuture error(error) do
    {:error, error, state}
  end

  @doc """
  Delay execution of a future for a period in milliseconds.

      iex> ok("Hello!") |> delay(10) |> fork!()
      "Hello!"

      iex> error(:foo) |> delay(10) |> fork()
      {:error, :foo}

      iex> ok("Hello") |> delay(10) |> map(&(&1 <> ", Joe")) |> fork!()
      "Hello, Joe"
  """

  @spec delay(Forkable.t, time_ms :: pos_integer) :: Forkable.t
  deffuture delay(future, time_ms) do
    Etude.Timer.call_after(fn(state) ->
      f(future, state)
    end, time_ms, state)
  end

  @doc """
  Wrap a function; catching any exceptions and returning them as `error` futures.
  """

  @spec wrap((() -> any)) :: Forkable.t
  deffuture wrap(fun) do
    try do
      {:ok, fun.(), state}
    rescue
      error ->
        {:error, error, state}
    catch
      _, error ->
        {:error, error, state}
    end
  end

  @doc """
  Apply a function over a successful future's value.

      iex> ok(1) |> map(&(&1 + &1)) |> fork!()
      2

      iex> ok(%{hello: nil}) |> map(&%{&1 | hello: "Robert"}) |> fork!()
      %{hello: "Robert"}
  """

  @spec map(Forkable.t, on_ok :: (any -> any)) :: Forkable.t
  deffuture map(future, on_ok) do
    f(future, state, fn(value, state) ->
      {:ok, on_ok.(value), state}
    end)
  end

  @doc """
  Apply a function over a future's error.

      iex> error(1) |> map_error(&(&1 + &1)) |> fork()
      {:error, 2}

      iex> error(%{hello: nil}) |> map_error(&%{&1 | hello: "Mike"}) |> fork()
      {:error, %{hello: "Mike"}}
  """

  @spec map_error(Forkable.t, on_error :: (any -> any)) :: Forkable.t
  deffuture map_error(future, on_error) do
    f(future, state, noop(), fn(error, state) ->
      {:error, on_error.(error), state}
    end)
  end

  @doc """
  Apply a function over a both the future's ok or error value.
  """

  @spec map_fold(Forkable.t, on_value :: (any -> any)) :: Forkable.t
  deffuture map_fold(future, on_value) do
    f(future, state, fn(value, state) ->
      {:ok, on_value.(value), state}
    end, fn(error, state) ->
      {:ok, on_value.(error), state}
    end)
  end

  @doc """
  Apply different functions over success and error values.
  """

  @spec map_over(Forkable.t, on_ok :: (any -> any), on_error :: (any -> any)) :: Forkable.t
  deffuture map_over(future, on_ok, on_error) do
    f(future, state, fn(value, state) ->
      {:ok, on_ok.(value), state}
    end, fn(error, state) ->
      {:error, on_error.(error), state}
    end)
  end

  @doc """
  Call a function when `future` returns ok and return a new future value.

      iex> ok(1) |> chain(&error(&1)) |> fork()
      {:error, 1}

      iex> ok(2) |> chain(&ok(&1 * 5)) |> fork!()
      10
  """

  @spec chain(Forkable.t, on_ok :: (any -> Forkable.t)) :: Forkable.t
  deffuture chain(future, on_ok) do
    f(future, state, fn(value, state) ->
      f(on_ok.(value), state)
    end)
  end

  @doc """
  Call a function when `future` returns an error and return a new future value.

      iex> error(1) |> chain_error(&ok(&1)) |> fork!()
      1

      iex> error(2) |> chain_error(&error(&1 * 5)) |> fork()
      {:error, 10}
  """

  @spec chain_error(Forkable.t, on_error :: (any -> Forkable.t)) :: Forkable.t
  deffuture chain_error(future, on_error) do
    f(future, state, noop(), fn(error, state) ->
      f(on_error.(error), state)
    end)
  end

  @doc """
  Call a function when `future` returns either an ok or error and return a new future value.
  """

  @spec chain_fold(Forkable.t, on_value :: (any -> Forkable.t)) :: Forkable.t
  deffuture chain_fold(future, on_value) do
    f(future, state, fn(value, state) ->
      f(on_value.(value), state)
    end, fn(error, state) ->
      f(on_value.(error), state)
    end)
  end

  @doc """
  Call one function when `future` returns an ok and another with error; where each one return a new future value.
  """

  @spec chain_over(Forkable.t, on_success :: (any -> Forkable.t), on_error :: (any -> Forkable.t)) :: Forkable.t
  deffuture chain_over(future, on_success, on_error) do
    f(future, state, fn(value, state) ->
      f(on_success.(value), state)
    end, fn(error, state) ->
      f(on_error.(error), state)
    end)
  end

  @doc """
  Execute a list of futures with an optional concurrency limit

  If any of the resulting futures fails, the pending futures will be canceled or not executed.

      iex> [ok(1), ok(2), ok(3)] |> join() |> fork!()
      [1, 2, 3]

      iex> [ok(4) |> delay(15),
      ...>  ok(5) |> delay(10),
      ...>  ok(6) |> delay(5)] |> join(1) |> fork!()
      [4, 5, 6]

      iex> [ok(7), ok(8), error(9)] |> join() |> fork()
      {:error, 9}
  """

  @spec join([Forkable.t], concurrency :: pos_integer | :infinity) :: Forkable.t
  def join(futures, concurrency \\ :infinity)
  def join([], _) do
    ok([])
  end
  def join([future], _) do
    %Etude.Map{future: future, on_ok: &[&1]}
  end
  def join(futures, concurrency) do
    Etude.Join.join(futures, concurrency)
  end

  @doc """
  Select the first `n` futures that return ok.

      iex> [ok(1), ok(2), ok(3)] |> select(2) |> fork!()
      [1, 2]

      iex> [ok(1) |> delay(5),
      ...>  ok(2) |> delay(10),
      ...>  ok(3) |> delay(6)] |> select(2) |> fork!()
      [1, 3]
  """

  @spec select([Forkable.t], count :: pos_integer) :: Forkable.t
  def select(futures, count)
  def select([], _count) do
    throw :empty_selection
  end
  def select(futures, count) when length(futures) >= count do
    Etude.Select.select(futures, count)
  end

  @doc """
  Select the first future that returns ok.

      iex> [ok(1), ok(2), ok(3)] |> select_first() |> fork!()
      1

      iex> [ok(1) |> delay(10),
      ...>  ok(2) |> delay(7),
      ...>  ok(3) |> delay(5)] |> select_first() |> fork!()
      3
  """

  @spec select_first([Forkable.t]) :: Forkable.t
  def select_first(futures)
  def select_first([future]) do
    future
  end
  def select_first(futures) do
    futures
    |> select(1)
    |> map(&:erlang.hd/1)
  end

  @doc """
  Retry a future until an ok value or the `limit` is reached.

      iex> wrap(fn ->
      ...>   if :rand.uniform() > 0.5 do
      ...>     throw :error
      ...>   else
      ...>     :foo
      ...>   end
      ...> end) |> retry() |> fork!()
      :foo
  """

  @spec retry(Forkable.t, limit :: pos_integer) :: Forkable.t
  @spec retry(Forkable.t, limit :: :infinity) :: Forkable.t | no_return
  def retry(future, limit \\ :infinity)
  def retry(future, 0) do
    future
  end
  def retry(future, :infinity) do
    chain_error(future, fn(_) ->
      retry(future, :infinity)
    end)
  end
  def retry(future, limit) when is_integer(limit) and limit >= 1 do
    chain_error(future, fn(_) ->
      retry(future, limit - 1)
    end)
  end

  @doc """
  Create a future that executes a `fun` in a `Task`.
  """

  def async(fun) do
    async(:erlang, :apply, [fun, []])
  end

  @doc """
  Create a future that calls `apply(mod, fun, args)` in a `Task`
  """

  deffuture async(mod, fun, args) do
    task = Task.async(mod, fun, args)
    f(task, state)
  end
end
