defimpl Etude.Matchable, for: [Map, Any] do
  alias Etude.Match.{Error,Executable,Literal}

  def compile(map) when map_size(map) == 0 do
    Literal.compile(map)
  end
  def compile(map) do
    l = map
    |> :maps.to_list()
    |> Enum.map(fn({key, value}) ->
      key = @protocol.compile_body(key)
      value = @protocol.compile(value)
      %Executable{
        module: __MODULE__,
        function: :__execute_kv__,
        env: {key, value}
      }
    end)

    %Executable{
      module: __MODULE__,
      env: l
    }
  end

  def __execute__(l, v, b) do
    v
    |> Etude.Future.to_term()
    |> Etude.Future.chain(fn
      (v) when is_map(v) ->
        l
        |> Enum.map(&Executable.execute(&1, v, b))
        |> Etude.Future.parallel()
        |> Etude.Future.map(&:maps.from_list/1)
      (v) ->
        Etude.Future.error(%Error{term: v, binding: b})
    end)
  end

  def __execute_kv__({key, value}, m, b) do
    key
    |> Executable.execute(b)
    |> Etude.Traversable.traverse()
    |> Etude.Future.chain(fn(k) ->
      case Map.fetch(m, k) do
        {:ok, v} ->
          value
          |> Executable.execute(v, b)
          |> Etude.Future.map(&({k, &1}))
        :error ->
          Etude.Future.error(%Error{term: m, binding: b})
      end
    end)
  end

  def compile_body(map) when map_size(map) == 0 do
    Literal.compile_body(map)
  end
  def compile_body(map) do
    funs = map
    |> :maps.to_list()
    |> Enum.map(fn({k, v}) ->
      k = @protocol.compile_body(k)
      v = @protocol.compile_body(v)

      %Executable{
        module: __MODULE__,
        function: :__execute_body_kv__,
        env: {k, v}
      }
    end)

    %Executable{
      module: __MODULE__,
      function: :__execute_body__,
      env: funs
    }
  end

  def __execute_body__(kvs, b) do
    kvs
    |> Enum.map(&Executable.execute(&1, b))
    |> Etude.Future.parallel()
    |> Etude.Future.map(&:maps.from_list/1)
  end

  def __execute_body_kv__({k, v}, b) do
    k
    |> Executable.execute(b)
    |> Etude.Future.map(fn(k) ->
      {k, Executable.execute(v, b)}
    end)
  end
end
