defprotocol Etude.Matchable do
  @fallback_to_any true

  def compile(value)
  def compile_body(value)
end

defmodule Etude.Match do
  alias Etude.Matchable
  alias __MODULE__.Executable
  require Etude.Future

  def binding(name) when is_atom(name) do
    %__MODULE__.Binding{name: name}
  end
  def binding(%__MODULE__.Binding{} = b) do
    b
  end

  def literal(value) do
    %__MODULE__.Literal{value: value}
  end

  def call(fun, args) do
    %__MODULE__.Call{fun: fun, args: args}
  end

  def binary(fun) do
    %__MODULE__.Binary{fun: fun}
  end

  def with_bindings(fun) do
    %__MODULE__.Scope{fun: fun}
  end

  def union(a, b) do
    %__MODULE__.Union{patterns: [a, b]}
  end

  def compile(pattern) do
    compile(pattern, true)
  end
  def compile(pattern, guard) do
    body = %__MODULE__.Scope{}
    compile_fun(pattern, guard, body)
  end
  def compile(pattern, guard, body) do
    compile_fun(pattern, guard, body)
  end

  defp compile_fun(pattern, nil, body) do
    compile_fun(pattern, true, body)
  end
  defp compile_fun(pattern, guard, body) do
    pattern = Matchable.compile(pattern)
    guard = Matchable.compile_body(guard)
    body = Matchable.compile_body(body)

    %Executable{
      module: __MODULE__,
      env: {pattern, guard, body}
    }
  end

  def __execute__(env, value, bindings) when is_map(bindings) do
    __execute__(env, value, {:erlang.unique_integer(), bindings})
  end
  def __execute__({pattern_e, guard_e, body_e}, value, {b, bindings}) when is_map(bindings) do
    pattern = Executable.execute(pattern_e, value, b)
    guard = Executable.execute(guard_e, b)
    body = Executable.execute(body_e, b)

    fn(state, rej, res) ->
      state = Etude.State.put_private(state, b, bindings)

      Etude.Forkable.fork(pattern, state, rej, fn(state, _) ->
        Etude.Forkable.fork(guard, state, rej, fn
          (state, true) ->
            Etude.Forkable.fork(body, state, rej, res)
          (state, value) ->
            %__MODULE__.Error{term: value, binding: b}
            |> Etude.Future.error()
            |> Etude.Forkable.fork(state, rej, res)
        end)
      end)
    end
    |> Etude.Future.new()
  end
end
