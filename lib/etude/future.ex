defmodule Etude.Future do
  defstruct [fun: nil, guarded: true, location: nil]
  alias Etude.{Forkable,State}

  defmodule Error do
    defexception [kind: :error, payload: nil, stacktrace: []]

    def message(%{payload: error}) do
      Exception.message(error)
    end
  end

  # creation

  defmacro put_location(future) do
    loc = extract_location(__CALLER__)
    quote do
      unquote(future)
      |> unquote(__MODULE__).location(unquote(Macro.escape(loc)))
    end
  end

  defmacro new(fun, guarded \\ true) do
    loc = extract_location(__CALLER__)
    quote do
      %unquote(__MODULE__){fun: unquote(fun), guarded: unquote(guarded)}
      |> unquote(__MODULE__).location(unquote(Macro.escape(loc)))
    end
  end

  defp extract_location(caller) do
    case caller do
      %{module: m, function: {fun, a}, file: f, line: l} ->
        f = Path.relative_to_cwd(f)
        {m, fun, a, [line: l, file: f]}
      %{file: f, line: l} ->
        f = Path.relative_to_cwd(f)
        {:erl_eval, :expr, 2, [line: l, file: f]}
    end
  end

  def forkable?(value) do
    Etude.Forkable.impl_for(value) != Etude.Forkable.Any
  end

  def of(value) do
    fn(state, _rej, res) ->
      res.(state, value)
    end
    |> new()
  end

  def reject(value) do
    fn(state, rej, _res) ->
      rej.(state, value)
    end
    |> new()
  end

  def mailbox(spawn, create_receiver) do
    fn(%{mailbox: mailbox} = state, rej, res) ->
      ref = mkref()
      cancel = spawn.(mailbox, ref) || &noop/1
      receiver = create_receiver.(rej, res, ref)
      {
        State.add_receiver(state, receiver),
        fn(state) ->
          cancel.()
          state
          |> State.delete_private(ref)
        end
      }
    end
    |> new()
  end

  def timeout(future, time) do
    delay(:timeout, time)
    |> chain(fn(_) ->
      wrap(fn -> throw :timeout end)
    end)
    |> concat(future)
    |> put_location()
  end

  def retry(future, 0) do
    future
  end
  def retry(future, :infinity) do
    future
    |> chain_rej(fn(_) ->
      retry(future, :infinity)
    end)
    |> put_location()
  end
  def retry(future, times) when times >= 1 do
    future
    |> chain_rej(fn(_) ->
      retry(future, times - 1)
    end)
    |> put_location()
  end

  def delay(value, time) do
    mailbox(fn(parent, ref) ->
      t = :erlang.send_after(time, parent, ref)
      fn() ->
        :erlang.cancel_timer(t)
      end
    end, fn(_rej, res, ref) ->
      fn
        (state, ^ref) ->
          {:done, State.schedule(state, &res.(&1, value))}
        (_, _) ->
          nil
      end
    end)
    |> put_location()
  end

  def wrap(fun) do
    encase(fun, [])
    |> put_location()
  end

  def encase(fun, args \\ []) do
    fn(state, rej, res) ->
      {call, value} =
        try do
          value = apply(fun, args)
          {res, value}
        rescue
          error ->
            stack = format_stack(state, System.stacktrace)
            {rej, %Error{payload: error, stacktrace: stack}}
        catch
          :throw, error ->
            stack = format_stack(state, System.stacktrace)
            {rej, %Error{kind: :throw, payload: error, stacktrace: stack}}
        end
      call.(state, value)
    end
    |> new()
  end

  defp format_stack(%{stack: stack}, [top | _]) do
    [top | stack]
    |> Enum.take(15)
  end

  # transform

  def location(future, location) do
    fun = fn(state, rej, res) ->
      state = State.push_location(state, location)
      pop = fn(fun) ->
        fn(state, value) ->
          state
          |> State.pop_location()
          |> fun.(value)
        end
      end
      f(future, state, pop.(rej), pop.(res))
    end
    %__MODULE__{fun: fun, location: location}
  end

  def map(future, f) do
    fn(state, rej, res) ->
      f(future, state, rej, &res.(&1, f.(&2)))
    end
    |> new()
  end

  def map_rej(future, f) do
    fn(state, rej, res) ->
      f(future, state, &rej.(&1, f.(&2)), res)
    end
    |> new()
  end

  def bimap(future, f, g) do
    fn(state, rej, res) ->
      f(future, state, &rej.(&1, f.(&2)), &res.(&1, g.(&2)))
    end
    |> new()
  end

  def chain(future, fun) do
    fn(state, rej, res) ->
      f(future, state, rej, fn(state, value) ->
        value
        |> fun.()
        |> f(state, rej, res)
      end)
    end
    |> new()
  end

  def chain_rej(future, fun) do
    fn(state, rej, res) ->
      f(future, state, fn(state, value) ->
        value
        |> fun.()
        |> f(state, rej, res)
      end, res)
    end
    |> new()
  end

  def ap(fun_f, args_f) do
    [fun_f, args_f]
    |> parallel()
    |> chain(fn([fun, args]) ->
      apply(fun, args)
    end)
    |> put_location()
  end

  def call(mod_f, fun_f, args_f) do
    [mod_f, fun_f, args_f]
    |> parallel()
    |> chain(fn([mod, fun, args]) ->
      wrap(fn() ->
        apply(mod, fun, args)
      end)
    end)
    |> put_location()
  end

  def swap(future) do
    fn(state, rej, res) ->
      f(future, state, res, rej)
    end
    |> new()
  end

  def hook(aquire_f, dispose, consume) do
    fn(state, rej, res) ->
      ref = mkref()

      {state, cancel} = f(aquire_f, state, rej, fn(state, resource) ->
        m = consume.(resource)
        create_dispose = fn(fun) ->
          fn(state, value) ->
            resource
            |> dispose.()
            |> f(state, rej, fn(_) -> fun.(value) end)
          end
        end
        {state, cancel} = f(m, state, create_dispose.(rej), create_dispose.(res))
        State.put_private(state, ref, cancel)
      end)

      {
        State.put_private(state, ref, cancel),
        fn(%{private: private} = state) ->
          {cancel, private} = Map.pop(private, ref)
          cancel.(%{state | private: private})
        end
      }
    end
    |> new()
  end

  def finally(future, call) do
    fn(state, rej, res) ->
      ref = mkref()

      done = fn(fun) ->
        fn(state, value) ->
          {state, cancel} = f(call, state, rej, fn(state, _) ->
            fun.(state, value)
          end)
          State.put_private(state, ref, cancel)
        end
      end

      {state, cancel} = f(future, state, done.(rej), done.(res))

      {
        State.put_private(state, ref, cancel),
        fn(%{private: private} = state) ->
          {cancel, private} = Map.pop(private, ref)
          cancel.(%{state | private: private})
        end
      }
    end
    |> new()
  end

  def fork(future, state) do
    ref = mkref()
    {state, cancel} = f(future, state, fn(state, error) ->
      State.put_private(state, ref, {:error, error})
    end, fn(state, value) ->
      State.put_private(state, ref, {:ok, value})
    end)
    {ref, state, cancel}
  end

  def await(%{private: private}, ref) do
    case Map.fetch(private, ref) do
      {:ok, value} ->
        value
      :error ->
        :cont
    end
  end

  def concat(a, b) do
    [a, b]
    |> race()
  end

  def race([a, b]) do
    fn(state, rej, res) ->
      ref = mkref()

      state = State.put_private(state, ref, {&noop/1, &noop/1, false})

      {%{private: private} = state, c1} = f(a, state, race_once(rej, ref), race_once(res, ref))
      case Map.get(private, ref) do
        {_, _, true} ->
          state
        _ ->
          {state, c2} = f(b, state, race_once(rej, ref), race_once(res, ref))

          state = State.update_private(state, ref, fn({_, _, status}) ->
            {c1, c2, status}
          end)

          {
            state,
            fn(%{private: private} = state) ->
              {{c1, c2, _}, private} = Map.pop(private, ref)
              %{state | private: private}
              |> c1.()
              |> c2.()
            end
          }
      end
    end
    |> new()
  end

  defp race_once(fun, ref) do
    fn(%{private: private} = state, value) ->
      case Map.get(private, ref) do
        {_, _, true} ->
          state
          |> State.delete_private(ref)
        {c1, c2, false} ->
          state
          |> c1.()
          |> c2.()
          |> State.put_private(ref, {c1, c2, true})
          |> fun.(value)
      end
    end
  end

  def fold(future, f, g) do
    fn(state, _rej, res) ->
      f(future, state, &res.(&1, f.(&2)), &res.(&1, g.(&2)))
    end
    |> new()
  end

  def parallel(futures, count \\ :infinity)
  def parallel([], _count) do
    of([])
  end
  def parallel(futures, count) when is_list(futures) and count >= 1 do
    init = {%{}, :pending, futures, 0, 0, %{}}
    fn(state, rej, res) ->
      ref = mkref
      {
        state |> State.put_private(ref, init) |> parallel_next(count, ref, rej, res),
        parallel_cancel(ref)
      }
    end
    |> new()
  end

  defp parallel_next(%{private: private} = state, count, ref, rej, res) do
    case Map.get(private, ref) do
      {_, :ok, _, _, _, _} ->
        state
      {_, :pending, _, _, pending, _} when pending >= count ->
        state
      {out, :pending, [], ids, _, _} when map_size(out) == ids ->
        state
        |> State.update_private(ref, fn(p) ->
          put_elem(p, 1, :ok)
        end)
        |> res.(:maps.values(out))
      {_, :pending, [], _, _, _} ->
        state
      {out, :pending, [future | futures], id, pending, cancels} ->
        state = State.update_private(state, ref, fn(_) ->
          {out, :pending, futures, id + 1, pending + 1, cancels}
        end)

        {state, cancel} =
          f(future, state, fn(state, error) ->
            parallel_cancel(ref).(state)
            |> rej.(error)
          end, fn(state, value) ->
            state
            |> State.update_private(ref, fn({out, status, futures, ids, pending, cancels}) ->
              {Map.put(out, id, value), status, futures, ids, pending - 1, Map.delete(cancels, id)}
            end)
            |> parallel_next(count, ref, rej, res)
          end)

        state
        |> State.update_private(ref, fn({out, status, futures, ids, pending, cancels}) ->
          {out, status, futures, ids, pending, Map.put(cancels, id, cancel)}
        end)
        |> parallel_next(count, ref, rej, res)
    end
  end

  defp parallel_cancel(ref) do
    fn(%{private: private} = state) ->
      case Map.get(private, ref) do
        {_, :pending, _, _, _, cancels} ->
          cancels
          |> Enum.reduce(state, fn({_, cancel}, state) ->
            cancel.(state)
          end)
        _ ->
          state
      end
    end
  end

  def cache(future, key \\ mkref) do
    fn(%{private: private} = state, rej, res) ->
      case Etude.Cache.get(state, key) do
        nil ->
          case Map.fetch(private, key) do
            {:ok, subs} ->
              %{state | private: Map.put(private, key, [{rej, res} | subs])}
            :error ->
              state = %{state | private: Map.put(private, key, [{rej, res}])}
              f(future, state, cache_handle(key, 0, :error), cache_handle(key, 1, :ok))
          end
        {:ok, value} ->
          res.(state, value)
        {:error, error} ->
          rej.(state, error)
      end
    end
    |> new()
  end

  defp cache_handle(key, elem, status) do
    fn(%{private: private} = state, value) ->
      state = Etude.Cache.put(state, key, {status, value})
      {cancels, state} =
        private
        |> Map.get(key)
        |> :lists.reverse()
        |> Enum.map_reduce(state, fn(handlers, state) ->
          fun = elem(handlers, elem)
          case fun.(state, value) do
            {state, cancel} ->
              {cancel, state}
            state ->
              {&noop/1, state}
          end
        end)
      {
        state,
        fn(state) ->
          Enum.reduce(cancels, state, fn(cancel, state) ->
            cancel.(state)
          end)
        end
      }
    end
  end

  #def match(pattern, guard, body) do
  #  Etude.Match.compile(pattern, guard, body)
  #end

  #def match(pattern, guard, body, value, bindings \\ %{}) do
  #  match(pattern, guard, body).(value, bindings)
  #end

  def to_term(future) do
    chain(future, fn(value) ->
      case Forkable.impl_for(value) do
        Forkable.Any ->
          of(value)
        _ ->
          to_term(value)
      end
    end)
  end

  defp f(future, state, rej, res) do
    case Forkable.fork(future, state, rej, res) do
      {state = %State{}, cancel} when is_function(cancel, 1) ->
        {state, cancel}
      state = %State{} ->
        {state, &noop/1}
    end
  end

  defp noop(s) do
    s
  end

  defp mkref() do
    :erlang.unique_integer()
  end
end

defimpl Inspect, for: Etude.Future do
  def inspect(%{location: nil}, _) do
    "#Etude.Future<>"
  end
  def inspect(%{location: {module, fun, a, _}}, _) do
    mfa = Exception.format_mfa(module, fun, a)
    "#Etude.Future<#{mfa}>"
  end
end
