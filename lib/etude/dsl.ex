defmodule Etude.DSL do
  defmacro defetude(qchildren, opts \\ []) do
    file = __CALLER__.file
    {children, _} = Code.eval_quoted(qchildren, __CALLER__.vars, __CALLER__)

    {:ok, mod, _main, bin} = "etude_#{Etude.Runtime.hash(children)}"
    |> String.to_atom
    |> Etude.compile(children, opts)

    load = "#{mod}_beam" |> String.to_atom
    for {fun, _} <- children do
      partial = "#{fun}_partial" |> String.to_atom
      quote do
        def unquote(fun)(state, resolve, req \\ :erlang.make_ref()) do
          unquote(load)()
          unquote(mod).unquote(fun)(state, resolve, req)
        end

        def unquote(partial)(state, resolve, req, scope, args) do
          unquote(load)()
          unquote(mod).unquote(partial)(state, resolve, req, scope, args)
        end

        defp unquote(load)() do
          if !:code.is_loaded(unquote(mod)) do
            :code.load_binary(unquote(mod), unquote(file |> String.to_char_list), unquote(bin))
          end
        end
      end
    end
  end
end
