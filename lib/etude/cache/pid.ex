defimpl Etude.Cache, for: PID do
  def get(pid, key) when pid == self do
    case Process.get(key) do
      {:ok, value} ->
        value
      nil ->
        nil
    end
  end

  def put(pid, key, value) when pid == self do
    Process.put(key, {:ok, value})
    pid
  end

  def memoize(pid, key, fun) when pid == self do
    case Process.get(key) do
      {:ok, value} ->
        {:ok, value, pid}
      nil ->
        value = fun.()
        {:ok, value, put(pid, key, value)}
    end
  end

  def delete(pid, key) when pid == self do
    Process.delete(key)
    pid
  end

  def clear(pid) when pid == self do
    :erlang.erase()
    pid
  end
end
