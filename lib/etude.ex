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
              vsn: vsn(children, opts),
              children: transform_children(children, opts)}
    |> Template.compile(opts)
    |> to_forms(opts)
    |> to_beam(Keyword.get(opts, :file, ""), opts[:erlc_options] || [])
  end

  def vsn(children, opts) do
    :erlang.phash2([children, opts])
  end

  defp to_forms({fun, contents}, _opts) do
    string = contents |> to_string |> String.to_char_list
    {:ok, tokens, _} = :erl_scan.string(string)
    {forms, _} = Enum.reduce(tokens, {[], []}, fn
      ({:dot, _} = dot, {forms, acc}) ->
        {:ok, form} = :erl_parse.parse_form(:lists.reverse([dot | acc]))
        {[form | forms], []}
      (token, {forms, acc}) ->
        {forms, [token | acc]}
    end)
    forms = forms
    |> :lists.reverse
    |> :rebind.parse_transform([])
    |> :lineo.parse_transform([])
    {fun, forms}
  end

  defp to_beam(forms, src, opts) when is_binary(src) do
    to_beam(forms, String.to_char_list(src), opts)
  end
  defp to_beam({fun, forms}, src, opts) do
    opts = [
      :binary,
      :report_errors,
      {:source, src},
      :no_error_module_mismatch
    ] ++ opts

    case :compile.forms(forms, opts) do
      {:ok, mod, bin} ->
        {:ok, mod, fun, bin}
      other ->
        other
    end
  end

  defp transform_children(children, opts) do
    children
    |> Etude.Passes.Scopes.transform(opts)
    |> Etude.Passes.SideEffects.transform(opts)
    # |> IO.inspect
  end
end
