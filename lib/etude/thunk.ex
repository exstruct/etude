defprotocol Etude.Thunk do
  import Kernel

  @functions [{:resolve, 2}|@functions]

  @spec resolve(Etude.Thunk.t, Etude.State.t) ::
    {Etude.Thunk.t, Etude.State.t} | {:await, Etude.Thunk.t, Etude.State.t}
  def resolve(thunk, state) do
    case impl_for(thunk) do
      nil ->
        {thunk, state}
      impl ->
        impl.resolve(thunk, state)
    end
  end
  Protocol.__spec__?(__MODULE__, :resolve, 2)

  @spec resolve(Etude.Thunk.t, Etude.State.t, function) ::
    {Etude.Thunk.t, Etude.State.t} | {:await, Etude.Thunk.t, Etude.State.t}
  def resolve(thunk, state, fun) do
    case resolve(thunk, state) do
      {value, state} ->
        fun.(value, state)
      {:await, thunk, state} ->
        {:await, %{__struct__: Etude.Thunk.Continuation, function: fn([t], s) -> resolve(t, s, fun) end, arguments: [thunk]}, state}
    end
  end

  @spec resolve_all([Etude.Thunk.t], Etude.State.t) ::
    {[Etude.Thunk.t], Etude.State.t} | {:await, [Etude.Thunk.t], Etude.State.t}
  def resolve_all(thunks, state) do
    {arguments, {ready?, state}} = Enum.map_reduce(thunks, {true, state}, fn(thunk, {ready?, state}) ->
      case resolve(thunk, state) do
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

  @spec resolve_all([Etude.Thunk.t], Etude.State.t, function) ::
    {Etude.Thunk.t, Etude.State.t} | {:await, Etude.Thunk.t, Etude.State.t}
  def resolve_all(thunks, state, fun) do
    case resolve_all(thunks, state) do
      {arguments, state} ->
        fun.(arguments, state)
      {:await, arguments, state} ->
        {:await, %{__struct__: Etude.Thunk.Continuation, function: fn(a, s) -> resolve_all(a, s, fun) end, arguments: arguments}, state}
    end
  end

  @spec resolved?(Etude.Thunk.t) :: boolean
  def resolved?(value) do
    impl_for(value) == nil
  end
end
