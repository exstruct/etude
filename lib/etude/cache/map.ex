defimpl Etude.Cache, for: Map do
  def get(cache, key) do
    Map.get(cache, key)
  end

  def put(cache, key, value) do
    Map.put(cache, key, value)
  end

  def put_new_lazy_and_return(cache, key, fun) do
    case Map.fetch(cache, key) do
      :error ->
        value = fun.()
        {value, Map.put(cache, key, value)}
      {:ok, value} ->
        {value, cache}
    end
  end

  def delete(cache, key) do
    Map.delete(cache, key)
  end

  def clear(_) do
    %{}
  end
end
