defmodule Etude.Macros do
  defmacro deffuture({name, meta, args}, [do: body]) do
    arity = length(args)
    mod = name |> to_string() |> Macro.camelize() |> String.to_atom()
    mod = Module.concat(__CALLER__.module, mod)
    struct = args |> Enum.map(&elem(&1, 0)) |> Macro.escape()
    fields = args |> Enum.map(&{elem(&1, 0), &1}) |> Macro.escape()
    body = Macro.escape(body)
    args = Macro.escape(args)

    loc = case __CALLER__ do
            %{module: m, file: file} ->
              {m, name, arity, [file: file, line: meta[:line]]}
          end |> Macro.escape()

    quote bind_quoted: [name: name,
                        args: args,
                        mod: mod,
                        struct: struct,
                        fields: fields,
                        body: body,
                        loc: loc] do

      def unquote(name)(unquote_splicing(args)) do
        %{unquote_splicing([{:__struct__, mod} | fields])}
      end

      defmodule mod do
        @moduledoc false
        defstruct struct

        defimpl Etude.Forkable do
          def fork(%{unquote_splicing(fields)}, var!(state), var!(stack)) do
            var!(loc) = unquote(Macro.escape(loc))
            var!(stack) = [var!(loc) | var!(stack)]
            _ = var!(stack)
            unquote(body)
          end
        end
      end
    end
  end

  defmacro f(future, state) do
    quote do
      Elixir.Etude.Forkable.fork(unquote(future), unquote(state), var!(stack))
    end
  end

  defmacro f(future, state, res) do
    rej = quote(do: noop())
    await = default_await(res, rej)
    compile_fork(future, state, res, rej, await)
  end

  defmacro f(future, state, res, rej) do
    await = default_await(res, rej)
    compile_fork(future, state, res, rej, await)
  end

  defmacro f(future, state, res, rej, await) do
    compile_fork(future, state, res, rej, await)
  end

  defp compile_fork(future, state, res, rej, await) do
    clauses = to_clauses(res, :ok) ++ to_clauses(rej, :error) ++ to_clauses(await, :await)
    call = quote do
      Elixir.Etude.Forkable.fork(unquote(future), unquote(state), var!(stack))
    end
    {:case, [], [call, [do: clauses]]}
  end

  defp to_clauses({:fn, _, clauses}, type) do
    Enum.map(clauses, fn({:->, _, [args, body]}) ->
      quote do
        {unquote_splicing([type | args])} ->
          unquote(body)
      end |> hd()
    end)
  end
  defp to_clauses({:noop, _, _}, type) do
    quote do
      {unquote(type), value, state} ->
        {unquote(type), value, state}
    end
  end

  defp default_await(res, rej) do
    clauses = to_clauses(res, :ok) ++ to_clauses(rej, :error)
    clauses = for {:->, m, [[{:{}, _, args}], body]} <- clauses do
      {:->, m, [args, body]}
    end
    fun = {:fn, [], clauses}
    quote do
      fn(register, state) ->
        state = Etude.State.link(state, register, unquote(fun))
        {:await, register, state}
      end
    end
  end
end
