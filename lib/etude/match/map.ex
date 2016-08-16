defimpl Etude.Matchable, for: [Map, Any] do
  alias Etude.Match.{Literal,Utils}

  def compile(map) when map_size(map) == 0 do
    Literal.compile(map)
  end
  def compile(map) do
    patterns = :maps.fold(fn(k, v, acc) ->
      k_p = @protocol.compile_body(k) # TODO this isn't exactly a body function
      v_p = @protocol.compile(v)
      [(&exec(k_p, v_p, &1, &2, &3)) | acc]
    end, [], map) |> :lists.reverse()

    fn(value, state, b) ->
      Etude.Thunk.resolve(value, state, fn
        (value, state) when is_map(value) ->
          Utils.exec_patterns(patterns, value, state, b)
        (_, state) ->
          {:error, state}
      end)
    end
  end

  def compile_body(map) when map_size(map) == 0 do
    Literal.compile_body(map)
  end
  def compile_body(map) do
    ## TODO OPTIMIZE write a version that doesn't convert between maps and keywords?
    keyword_b = :maps.to_list(map) |> @protocol.compile_body()
    fn(state, b) ->
      case keyword_b.(state, b) do
        {:ok, keyword, state} ->
          {:ok, :maps.from_list(keyword), state}
        error ->
          error
      end
    end
  end

  defp exec(k_p, v_p, map, state, b) do
    case k_p.(state, b) do
      {:ok, key, state} ->
        Etude.Thunk.resolve_recursive(key, state, fn(key, state) ->
          exec_value(key, v_p, map, state, b)
        end)
      {:error, state} ->
        {:error, state}
    end
  end

  defp exec_value(key, v_p, map, state, b) do
    case Map.fetch(map, key) do
      :error ->
        {:error, state}
      {:ok, value} ->
        case v_p.(value, state, b) do
          {:await, thunk, state} ->
            Utils.continuation(thunk, state, fn(value, state) ->
              exec_value(key, v_p, Map.put(map, key, value), state, b)
            end)
          {:ok, value, state} ->
            {:ok, Map.put(map, key, value), state}
          {:error, state} ->
            {:error, state}
        end
    end
  end
end
