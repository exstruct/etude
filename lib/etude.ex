defmodule Etude do
  @vsn Mix.Project.config[:version]
  alias Etude.State
  import Etude.Macros

  @doc """
  Start execution of a future with the default %Etude.State{}

  See fork/2
  """
  def fork(future) do
    case fork(future, %Etude.State{}) do
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
    case Etude.Forkable.fork(future, state, []) do
      {:ok, value, state} ->
        {:ok, value, state}
      {:error, error, state} ->
        {:error, error, state}
      {:await, register, state} ->
        State.await(state, register)
    end
  end

  @doc """
  Wrap a value in a future.

      iex> 1 |> value() |> fork!()
      1

      iex> %{hello: "Joe"} |> value() |> fork!()
      %{hello: "Joe"}
  """
  deffuture value(value) do
    {:ok, value, state}
  end

  @doc """
  Send a value after a number of milliseconds.

      iex> value_after("Hello!", 10) |> fork!()
      "Hello!"

      iex> value_after("Hello", 10) |> map(&(&1 <> ", Joe")) |> fork!()
      "Hello, Joe"
  """
  deffuture value_after(value, time) do
    Etude.Timer.call_after(fn(state) ->
      {:ok, value, state}
    end, time, state)
  end

  @doc """
  Wrap an error in a future.

      iex> 1 |> error() |> fork()
      {:error, 1}

      iex> %{uh: :oh} |> error() |> fork()
      {:error, %{uh: :oh}}
  """
  deffuture error(error) do
    {:error, error, state}
  end

  @doc """
  Send an error after a number of milliseconds.

      iex> error_after("Woops", 10) |> fork()
      {:error, "Woops"}

      iex> error_after("Woops", 10) |> map_error(&(&1 <> "!")) |> fork()
      {:error, "Woops!"}
  """
  deffuture error_after(value, time) do
    Etude.Timer.call_after(fn(state) ->
      {:error, value, state}
    end, time, state)
  end

  @doc """

  """
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

      iex> value(1) |> map(&(&1 + &1)) |> fork!()
      2

      iex> value(%{hello: nil}) |> map(&%{&1 | hello: "Robert"}) |> fork!()
      %{hello: "Robert"}
  """
  deffuture map(future, on_success) do
    f(future, state, fn(value, state) ->
      {:ok, on_success.(value), state}
    end)
  end

  @doc """
  Apply a function over a future's error.

      iex> error(1) |> map_error(&(&1 + &1)) |> fork()
      {:error, 2}

      iex> error(%{hello: nil}) |> map_error(&%{&1 | hello: "Mike"}) |> fork()
      {:error, %{hello: "Mike"}}
  """
  deffuture map_error(future, on_error) do
    f(future, state, noop(), fn(error, state) ->
      {:error, on_error.(error), state}
    end)
  end

  @doc """

  """
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
  deffuture map_over(future, on_success, on_error) do
    f(future, state, fn(value, state) ->
      {:ok, on_success.(value), state}
    end, fn(error, state) ->
      {:error, on_error.(error), state}
    end)
  end

  @doc """

      iex> value(1) |> chain(&error(&1)) |> fork()
      {:error, 1}

      iex> value(2) |> chain(&value(&1 * 5)) |> fork!()
      10
  """
  deffuture chain(future, on_success) do
    f(future, state, fn(value, state) ->
      f(on_success.(value), state)
    end)
  end

  @doc """

      iex> error(1) |> chain_error(&value(&1)) |> fork!()
      1

      iex> error(2) |> chain_error(&error(&1 * 5)) |> fork()
      {:error, 10}
  """
  deffuture chain_error(future, on_error) do
    f(future, state, noop(), fn(error, state) ->
      f(on_error.(error), state)
    end)
  end

  @doc """

  """
  deffuture chain_fold(future, on_value) do
    f(future, state, fn(value, state) ->
      f(on_value.(value), state)
    end, fn(error, state) ->
      f(on_value.(error), state)
    end)
  end

  @doc """

  """
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

      iex> [value(1), value(2), value(3)] |> join() |> fork!()
      [1, 2, 3]

      iex> [value_after(4, 15), value_after(5, 10), value_after(6, 5)] |> join(1) |> fork!()
      [4, 5, 6]

      iex> [value(7), value(8), error(9)] |> join() |> fork()
      {:error, 9}
  """
  def join(futures, concurrency \\ :infinity)
  def join([], _) do
    value([])
  end
  def join([future], _) do
    %Etude.Map{future: future, on_success: &[&1]}
  end
  def join(futures, concurrency) do
    Etude.Join.join(futures, concurrency)
  end

  @doc """

      iex> [value(1), value(2), value(3)] |> select(2) |> fork!()
      [1, 2]

      iex> [value_after(1, 5), value_after(2, 10), value_after(3, 6)] |> select(2) |> fork!()
      [1, 3]
  """
  def select(futures, count)
  def select([], _count) do
    throw :empty_selection
  end
  def select(futures, count) do
    Etude.Select.select(futures, count)
  end

  @doc """

      iex> [value(1), value(2), value(3)] |> select_first() |> fork!()
      1

      iex> [value_after(1, 10), value_after(2, 7), value_after(3, 5)] |> select_first() |> fork!()
      3
  """
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

      iex> wrap(fn ->
      ...>   if :rand.uniform() > 0.5 do
      ...>     throw :error
      ...>   else
      ...>     :foo
      ...>   end
      ...> end) |> retry() |> fork!()
      :foo
  """
  def retry(future, count \\ :infinity)
  def retry(future, 0) do
    future
  end
  def retry(future, :infinity) do
    chain_error(future, fn(_) ->
      retry(future, :infinity)
    end)
  end
  def retry(future, times) when is_integer(times) and times >= 1 do
    chain_error(future, fn(_) ->
      retry(future, times - 1)
    end)
  end
end
