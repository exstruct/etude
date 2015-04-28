defmodule Etude do
  alias Etude.Template

  defmodule DSL do
    defmacro defetude(qname, qchildren, opts \\ []) do
      file = __CALLER__.file
      {name, _} = Code.eval_quoted(qname, __CALLER__.vars, __CALLER__)
      {children, _} = Code.eval_quoted(qchildren, __CALLER__.vars, __CALLER__)

      {:ok, mod, fun, bin} = Etude.compile(String.to_atom("etude_#{:erlang.phash2(children)}"), children, [function: name] ++ opts)
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

  defmacro __using__(_) do
    ## TODO allow disabling the native compilation
    quote do
      require Logger
      import Etude.DSL
      @compile :native
      @compile {:hipe, [:o3]}
      @compile :inline_list_funcs
      @compile :nowarn_unused_vars
    end
  end

  def compile(name, children, opts \\ []) do
    %Template{name: name,
              children: transform_children(children, opts)}
    |> Template.compile(opts)
    |> to_beam(Keyword.get(opts, :file, ""))
  end

  defp to_beam({fun, str}, src) do
    file = "/tmp/etude_#{:erlang.phash2(:os.timestamp())}.erl"

    opts = [
      :binary,
      :report_errors,
      {:source, src |> String.to_char_list},
      :no_error_module_mismatch
    ]

    File.write!(file, str)
    res = case :compile.file(file |> String.to_char_list, opts) do
      {:ok, mod, bin} ->
        {:ok, mod, fun, bin}
      other ->
        other
    end
    File.rm!(file)
    res
  end

  defp transform_children(children, opts) do
    children
    |> Etude.Passes.SideEffects.transform(opts)
  end
end
