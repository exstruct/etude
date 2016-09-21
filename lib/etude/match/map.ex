defimpl Etude.Matchable, for: [Map, Any] do
  alias Etude.Match.Literal

  def compile(map) when map_size(map) == 0 do
    Literal.compile(map)
  end
  def compile(map) do
    l = Enum.map(map, fn({key, value}) ->
      key_fun = @protocol.compile_body(key)
      value_fun = @protocol.compile(value)
      fn(m, b) ->
        b
        |> key_fun.()
        |> Etude.Traversable.traverse()
        |> Etude.Future.chain(fn(k) ->
          case Map.fetch(m, k) do
            {:ok, v} ->
              v
              |> value_fun.(b)
              |> Etude.Future.map(&({k, &1}))
            :error ->
              Etude.Future.reject(%MatchError{term: m})
          end
        end)
      end
    end)

    fn(v, b) ->
      v
      |> Etude.Future.to_term()
      |> Etude.Future.chain(fn
        (v) when is_map(v) ->
          l
          |> Enum.map(&(&1.(v, b)))
          |> Etude.Future.parallel()
          |> Etude.Future.map(&:maps.from_list/1)
        (v) ->
          Etude.Future.reject(%MatchError{term: v})
      end)
    end
  end

  def compile_body(map) when map_size(map) == 0 do
    Literal.compile_body(map)
  end
  def compile_body(map) do
    funs = map
    |> :maps.to_list()
    |> Enum.map(fn({k, v}) ->
      k_f = @protocol.compile_body(k)
      v_f = @protocol.compile_body(v)
      fn(b) ->
        b
        |> k_f.()
        |> Etude.Future.map(fn(k) ->
          {k, v_f.(b)}
        end)
      end
    end)

    fn(b) ->
      funs
      |> Enum.map(&(&1.(b)))
      |> Etude.Future.parallel()
      |> Etude.Future.map(&:maps.from_list/1)
    end
  end
end
