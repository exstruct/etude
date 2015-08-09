defmodule Etude.Async do
  def send(%{parent: parent, ref: ref}, {:ok, message}) do
    :erlang.send(parent, {:ok, message, ref})
  end
  def send(%{parent: parent, ref: ref}, {:error, error}) do
    :erlang.send(parent, {:error, error, ref})
  end

  def spawn(op, fun) do
    spawn(fn ->
      Etude.Async.send(op, fun.())
    end)
  end
end
