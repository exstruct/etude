defprotocol Etude.Thunk do
  import Kernel

  @functions [{:resolve, 2}|@functions]

  defmacrop try_resolve(value) do
    quote do
      case unquote(value) do
        {value, state} ->
          resolve(value, state)
        other ->
          other
      end
    end
  end

  defmacrop try_resolve_once(value) do
    value
  end

  for {suffix, chain} <- [{"", :try_resolve}, {"_once", :try_resolve_once}] do
    resolve = :"resolve#{suffix}"
    resolve_all = :"resolve_all#{suffix}"

    @spec unquote(resolve)(Etude.Thunk.t, Etude.State.t) ::
      {Etude.Thunk.t, Etude.State.t} | {:await, Etude.Thunk.t, Etude.State.t}
    def unquote(resolve)(thunk, state) do
      case impl_for(thunk) do
        nil ->
          {thunk, state}
        impl ->
          impl.resolve(thunk, state)
          |> unquote(chain)()
      end
    end

    @spec unquote(resolve)(Etude.Thunk.t, Etude.State.t, function) ::
      {Etude.Thunk.t, Etude.State.t} | {:await, Etude.Thunk.t, Etude.State.t}
    def unquote(resolve)(thunk, state, fun) do
      case unquote(resolve)(thunk, state) do
        {value, state} ->
          fun.(value, state)
          |> unquote(chain)()
        {:await, thunk, state} ->
          {:await, %{__struct__: Etude.Thunk.Continuation,
                     function: fn([t], s) -> unquote(resolve)(t, s, fun) end,
                     arguments: [thunk]}, state}
      end
    end

    @spec unquote(resolve_all)([Etude.Thunk.t], Etude.State.t) ::
      {[Etude.Thunk.t], Etude.State.t} | {:await, [Etude.Thunk.t], Etude.State.t}
    def unquote(resolve_all)(thunks, state) do
      {arguments, {ready?, state}} = Enum.map_reduce(thunks, {true, state}, fn(thunk, {ready?, state}) ->
        case unquote(resolve)(thunk, state) do
          {value, state} ->
            {value, {ready?, state}}
          {:await, thunk, state} ->
            {thunk, {false, state}}
        end
      end)

      if ready? do
        {arguments, state}
      else
        {:await, arguments, state}
      end
    end

    @spec unquote(resolve_all)([Etude.Thunk.t], Etude.State.t, function) ::
      {Etude.Thunk.t, Etude.State.t} | {:await, Etude.Thunk.t, Etude.State.t}
    def unquote(resolve_all)(thunks, state, fun) do
      case unquote(resolve_all)(thunks, state) do
        {arguments, state} ->
          fun.(arguments, state)
          |> unquote(chain)()
        {:await, arguments, state} ->
          {:await, %{__struct__: Etude.Thunk.Continuation,
                     function: fn(a, s) -> unquote(resolve_all)(a, s, fun) end,
                     arguments: arguments}, state}
      end
    end
  end

  def resolve_recursive(value, state) do
    Etude.Serializer.TERM.__serialize__(value, state)
  end

  def resolve_recursive(term, state, fun) do
    case resolve_recursive(term, state) do
      {value, state} ->
        fun.(value, state)
      {:await, thunk, state} ->
        {:await, %{__struct__: Etude.Thunk.Continuation,
                   function: fn(a, s) -> resolve_recursive(a, s, fun) end,
                   arguments: thunk}, state}
    end
  end

  Protocol.__spec__?(__MODULE__, :resolve, 2)

  @spec resolved?(Etude.Thunk.t) :: boolean
  def resolved?(value) do
    impl_for(value) == nil
  end
end
