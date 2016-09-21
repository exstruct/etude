defprotocol Etude.Matchable do
  @fallback_to_any true

  def compile(value)
  def compile_body(value)
end

defmodule Etude.Match do
  alias Etude.Matchable
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

  def compile({pattern, guard, body}) do
    compile(pattern, guard, body)
  end
  def compile(pattern, guard, body) do
    compile_fun(pattern, guard, body)
  end

  defp compile_fun(pattern, nil, body) do
    compile_fun(pattern, true, body)
  end
  defp compile_fun(pattern, guard, body) do
    pattern_fun = Matchable.compile(pattern)
    guard_fun = Matchable.compile_body(guard)
    body_fun = Matchable.compile_body(body)

    fn(value, bindings) ->
      b = :erlang.make_ref()

      pattern = pattern_fun.(value, b)
      guard = guard_fun.(b)
      body = body_fun.(b)

      fn(state, rej, res) ->
        state = Etude.State.put_private(state, b, bindings)

        Etude.Forkable.fork(pattern, state, rej, fn(state, _) ->
          Etude.Forkable.fork(guard, state, rej, fn
            (state, true) ->
              Etude.Forkable.fork(body, state, rej, res)
            (state, value) ->
              rej.(state, %CaseClauseError{term: value})
          end)
        end)
      end
      |> Etude.Future.new()
    end
  end
end
