defprotocol Etude.Matchable do
  @fallback_to_any true

  def compile(value)
  def compile_body(value)
end

defmodule Etude.Match do
  alias Etude.Matchable
  alias Etude.Match.Utils

  defstruct [:fun]

  def binding(name) do
    %__MODULE__.Binding{name: name}
  end

  def literal(value) do
    %__MODULE__.Literal{value: value}
  end

  @guard_0 ~w(
    node self
  )a

  @guard_1 ~w(
    is_atom is_float is_integer is_list is_number is_pid is_port is_reference is_tuple is_map is_binary is_function

    not abs hd length map_size round size tl tuple_size trunc
  )a

  @guard_2 ~w(
    and or xor andalso orelse

    element + - * div rem band bor bxor bnot bsl bsr > >= < =< =:= == =/= /=
  )a

  def call(fun, args) when ((fun in @guard_0) and length(args) == 0) or
                           ((fun in @guard_1) and length(args) == 1) or
                           ((fun in @guard_2) and length(args) == 2) do
    %__MODULE__.Call{fun: fun, args: args}
  end

  def compile({pattern, guard, body}) do
    compile(pattern, guard, body)
  end
  def compile(pattern, guard, body) do
    %__MODULE__{fun: compile_fun(pattern, guard, body)}
  end

  def exec(%__MODULE__{fun: fun}, value, state, b) do
    fun.(value, state, b)
  end

  defp compile_fun(pattern, nil, body) do
    compile_fun(pattern, true, body)
  end
  defp compile_fun(pattern, guard, body) do
    pattern_fun = Matchable.compile(pattern)
    guard_fun = Matchable.compile_body(guard)
    body_fun = Matchable.compile_body(body)

    exec_guard = &exec_guard_fun(guard_fun, body_fun, &1, &2)

    fn(value, state, bindings) ->
      bindings_ref = :erlang.make_ref()
      state = Etude.State.put_private(state, bindings_ref, bindings)
      exec_pattern_fun(pattern_fun, exec_guard, value, state, bindings_ref)
    end
  end

  defp exec_pattern_fun(pattern_fun, guard_fun, value, state, b) do
    case pattern_fun.(value, state, b) do
      {:ok, _, state} ->
        guard_fun.(state, b)
      {:await, thunk, state} ->
        Utils.continuation(thunk, state, &exec_pattern_fun(pattern_fun, guard_fun, &1, &2, b))
      {:error, state} ->
        {:error, state}
    end
  end

  def exec_guard_fun(guard_fun, body_fun, state, b) do
    case guard_fun.(state, b) do
      {:ok, guard_thunk, state} ->
        Etude.Thunk.resolve_recursive(guard_thunk, state, fn
          (true, state) ->
            body_fun.(state, b)
          (_, state) ->
            {:error, state}
        end)
      {:error, state} ->
        {:error, state}
    end
  end
end
