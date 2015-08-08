defprotocol Etude.Dict do
  @fallback_to_any true

  @type key :: any
  @type value :: any
  @type error :: {:error, any, t}
  @type thunk :: {:pending, t} | {:pending, pid, t}
  @type double_thunk :: {:pending, t, t} | {:pending, nil, t, nil, t}
  @type op_ref :: Etude.Dict.OpRef
  @type t :: list | map

  @spec cache_key(t) :: term
  def cache_key(dict)

  @spec delete(t, key, op_ref) :: {:ok, t} | thunk | error
  def delete(dict, key, op_ref)

  @spec drop(t, Enum.t, op_ref) :: {:ok, t} | thunk | error
  def drop(dict, enum, op_ref)

  @spec equal?(t, t, op_ref) :: {:ok, boolean, t, t} | double_thunk | {:error, error, t, t}
  def equal?(dict, t, op_ref)

  @spec get(t, key, op_ref) :: {:ok, value, t} | thunk | error
  def get(dict, key, op_ref)

  @spec get(t, key, op_ref, value) :: {:ok, value, t} | thunk | error
  def get(dict, key, op_ref, value)

  @spec fetch(t, key, op_ref) :: {:ok, value, t} | {:error, t} | thunk | error
  def fetch(dict, key, op_ref)

  @spec has_key?(t, key, op_ref) :: {:ok, boolean, t} | thunk | error
  def has_key?(dict, key, op_ref)

  @spec keys(t, op_ref) :: {:ok, [key], t} | thunk | error
  def keys(dict, op_ref)

  @spec load(t, op_ref) :: {:ok, t} | thunk | error
  def load(dict, op_ref)

  @spec merge(t, t, op_ref) :: {:ok, t} | thunk | error
  def merge(dict1, dict2, op_ref)

  @spec merge(t, t, op_ref, (key, value, value -> value)) :: {:ok, t} | thunk | error
  def merge(dict1, dict2, op_ref, mapper)

  @spec pop(t, key, op_ref) :: {:ok, value, t} | thunk | error
  def pop(dict, key, op_ref)

  @spec pop(t, key, op_ref, value) :: {:ok, value, t} | thunk | error
  def pop(dict, key, op_ref, value)

  @spec put(t, key, value, op_ref) :: {:ok, t} | thunk | error
  def put(dict, key, value, op_ref)

  @spec put_new(t, key, value, op_ref) :: {:ok, t} | thunk | error
  def put_new(dict, key, value, op_ref)

  @spec reduce(t, Enumerable.acc, function, op_ref) :: {:done, term, t} | {:halted, term, t} | thunk | error
  def reduce(dict, acc, fun, _op_ref)

  @spec size(t, op_ref) :: {:ok, non_neg_integer, t} | thunk | error
  def size(dict, op_ref)

  @spec to_list(t, op_ref) :: {:ok, list} | thunk | error
  def to_list(dict, op_ref)

  @spec update(t, key, value, (value -> value), op_ref) :: {:ok, t} | thunk | error
  def update(dict, key, value, mapper, op_ref)

  @spec values(t, op_ref) :: {:ok, [value], t} | thunk | error
  def values(dict, op_ref)

  Kernel.defmacro __using__(_) do
    quote do
      @behaviour Etude.Dict

      def drop(dict, keys, op_ref) do
        try do
          {:ok, Enum.reduce(keys, dict, fn(key, dict) ->
            case delete(dict, key, op_ref) do
              {:ok, dict} ->
                dict
              other ->
                throw dict
            end
          end)}
        catch
          other ->
            other
        end
      end

      def equal?(dict1, dict2, op_ref) do
        :erlang.raise :error, :equal_not_implemented, System.stacktrace

        import Kernel, except: [size: 1]

        case {size(dict1, op_ref), Etude.Dict.size(dict2, op_ref)} do
          {{:ok, s, dict1}, {:ok, s, dict2}} ->
            # TODO
        end
      end

      def get(dict, key, op_ref, default \\ nil) do
        case fetch(dict, key, op_ref) do
          {:ok, value_or_pid, dict} ->
            {:ok, value_or_pid, dict}
          {:pending, t} ->
            {:pending, t}
          {:error, dict} ->
            {:ok, default, dict}
          {:error, error, dict} ->
            {:error, error, dict}
        end
      end

      def has_key?(dict, key, op_ref) do
        case fetch(dict, key, op_ref) do
          {:ok, _, dict} ->
            {:ok, true, dict}
          {:error, dict} ->
            {:ok, false, dict}
          other ->
            other
        end
      end

      def keys(dict, op_ref) do
        return = reduce(dict, {:cont, []}, fn
          {k, _}, acc -> {:cont, [k | acc]}
        end, op_ref)

        case return do
          {status, acc, dict} when status in [:done, :halted] ->
            {:ok, :lists.reverse(acc), dict}
          other ->
            other
        end
      end

      def merge(t, t, op_ref) do
        :erlang.raise :error, :merge_not_implemented, System.stacktrace
      end

      def merge(t, t, op_ref, mapper) do
        :erlang.raise :error, :merge_not_implemented, System.stacktrace
      end

      def pop(dict, key, op_ref, default \\ nil) do
        case fetch(dict, key, op_ref) do
          {:ok, pid, dict} when is_pid(pid) ->
            {:ok, pid, dict}
          {:ok, value, dict} ->
            {:ok, value, delete(dict, key, op_ref)}
          {:error, dict} ->
            {:ok, default, dict}
          other ->
            other
        end
      end

      def put_new(dict, key, value, op_ref) do
        case has_key?(dict, key, op_ref) do
          {:ok, false, dict} ->
            put(dict, key, value, op_ref)
          {:ok, true, dict} ->
            {:ok, dict}
          other ->
            other
        end
      end

      def reduce(dict, acc, fun, op_ref) do
        {initial_status, acc} = acc

        return = Enumerable.reduce(dict, {initial_status, {acc, dict}}, fn({key, _}, {acc, dict}) ->
          case fetch(dict, key, op_ref) do
            {:ok, value, dict} ->
              {status, acc} = fun.({key, value}, acc)
              {status, {acc, dict}}
            {:error, error, dict} ->
              {:halt, {:error, error, dict}}
            {:pending, dict} ->
              {:halt, {:pending, dict}}
            {:pending, pid, dict} ->
              {:halt, {:pending, pid, dict}}
          end
        end)

        case return do
          {:done, {acc, dict}} ->
            {:done, acc, dict}
          {:halted, {:pending, dict}} ->
            {:pending, dict}
          {:halted, {:pending, pid, dict}} ->
            {:pending, pid, dict}
          {:halted, {:error, error, dict}} ->
            {:error, error, dict}
          {:halted, {acc, dict}} ->
            {:halted, acc, dict}
        end
      end

      def to_list(dict, op_ref) do
        return = reduce(dict, {:cont, []}, fn
          kv, acc -> {:cont, [kv | acc]}
        end, op_ref)

        case return do
          {status, acc, dict} when status in [:done, :halted] ->
            {:ok, :lists.reverse(acc), dict}
          other ->
            other
        end
      end

      def update(dict, key, value, fun, op_ref) do
        case fetch(dict, key, op_ref) do
          {:ok, value, dict} ->
            case fun.(value) do
              {:ok, value} ->
                put(dict, key, value, op_ref)
              ## TODO how will the fun return other values but still have the dict return its new value
            end
          {:error, dict} ->
            put(dict, key, value, op_ref)
          other ->
            other
        end
      end

      def values(dict, op_ref) do
        return = reduce(dict, {:cont, []}, fn
          {_, v}, acc -> {:cont, [v | acc]}
        end, op_ref)

        case return do
          {status, acc, dict} when status in [:done, :halted] ->
            {:ok, :lists.reverse(acc), dict}
          other ->
            other
        end
      end

      defoverridable drop: 3,
                     equal?: 3,
                     get: 3,
                     get: 4,
                     has_key?: 3,
                     keys: 2,
                     merge: 3,
                     merge: 4,
                     pop: 3,
                     pop: 4,
                     put_new: 4,
                     reduce: 4,
                     to_list: 2,
                     update: 5,
                     values: 2
    end
  end
end

for {type, impl} <- [Map: Map, List: Keyword, Any: Dict] do
  defimpl Etude.Dict, for: type do
    use Etude.Dict

    def cache_key(dict) do
      {unquote(if impl == Dict do
        quote do
          Map.get(var!(dict), :__struct__)
        end
      else
        impl
      end), :erlang.phash2(dict)}
    end

    def delete(dict, key, op_ref) do
      case fetch(dict, key, op_ref) do
        {:error, dict} ->
          {:ok, dict}
        {:ok, _, dict} ->
          {:ok, unquote(impl).delete(dict, key)}
      end
    end

    def fetch(dict, key, _op_ref) do
      case unquote(impl).fetch(dict, key) do
        {:ok, value} ->
          {:ok, value, dict}
        :error ->
          {:error, dict}
      end
    end

    def load(dict, _op_ref) do
      {:ok, dict}
    end

    def put(dict, key, value, _op_ref) do
      {:ok, unquote(impl).put(dict, key, value)}
    end

    def size(dict, _op_ref) do
      {:ok, unquote(impl).size(dict), dict}
    end
  end
end