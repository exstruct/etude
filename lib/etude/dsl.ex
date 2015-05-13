defmodule Etude.DSL do
  defmacro defetude(qname, qchildren, opts \\ []) do
    file = __CALLER__.file
    {name, _} = Code.eval_quoted(qname, __CALLER__.vars, __CALLER__)
    {children, _} = Code.eval_quoted(qchildren, __CALLER__.vars, __CALLER__)

    {:ok, mod, fun, bin} = Etude.compile(String.to_atom("etude_#{:erlang.phash2(children)}"), children, [main: name] ++ opts)
    load = "#{name}_beam" |> String.to_atom
    partial = "#{fun}_partial" |> String.to_atom
    quote do
      def unquote(name)(state, resolve, req \\ :erlang.make_ref()) do
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