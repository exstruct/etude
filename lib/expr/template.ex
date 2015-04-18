defmodule Expr.Template do
  defstruct name: nil,
            line: 1,
            children: []

  import Expr.Utils
  import Expr.Vars

  defimpl String.Chars, for: Expr.Template do
    def to_string(template) do
      Expr.Template.compile(template)
      |> Macro.to_string
    end
  end

  def compile(template, opts \\ []) do
    name = template.name
    line = template.line
    timeout = Keyword.get(opts, :timeout, 5000)

    opts = Keyword.put_new(opts, :prefix, name)

    partial = "#{name}_partial" |> String.to_atom
    loop = "#{name}_loop" |> String.to_atom
    wait = "#{name}_wait" |> String.to_atom
    immediate = "#{name}_wait_immediate" |> String.to_atom

    root = Expr.Children.root(template.children, opts)

    quote line: line do
      require Expr.Memoize

      def unquote(name)(state, resolve, req \\ :erlang.make_ref()) do
        Logger.debug(unquote("#{name} init"))
        unquote(loop)(0, state, resolve, req, nil)
      end

      def unquote(partial)(unquote_splicing(op_args), args) do
        Logger.debug(unquote("#{name} partial"))
        Expr.Memoize.put({unquote(name), :__ARGS__}, args)
        case unquote(root) do
          {{unquote(ready), _} = val, state} ->
            {val, state}
          {unquote(ready), _} = val ->
            {val, unquote(state)}
          other ->
            other
        end
      end

      defp unquote(loop)(count, unquote_splicing(op_args)) do
        Logger.debug(fn -> unquote("#{name} loop (") <> to_string(count) <> ")" end)
        case unquote(root) do
          {{unquote(ready), val}, state} ->
            {val, state}
          {unquote(ready), val} ->
            {val, unquote(state)}
          {nil, unquote(state)} ->
            unquote(wait)(count + 1, unquote_splicing(op_args))
        end
      end

      defp unquote(wait)(count, unquote_splicing(op_args)) do
        Logger.debug(fn -> unquote("#{name} wait (") <> to_string(count) <> ")" end)
        unquote(wait_block(immediate, timeout, line, quote do
          {:error, :timeout}
        end))
      end

      defp unquote(immediate)(count, unquote_splicing(op_args)) do
        Logger.debug(fn -> unquote("#{name} wait[immediate] (") <> to_string(count) <> ")" end)
        unquote(wait_block(immediate, 0, line, quote do
          unquote(loop)(count + 1, unquote_splicing(op_args))
        end))
      end

      unquote_splicing(Expr.Children.compile(template.children, opts))
    end
  end

  defp wait_block(name, timeout, line, loop) do
    quote line: line do
      receive do
        {:ok, val, {ref, key}} when is_reference(ref) ->
          out = {unquote(ready), val}
          Expr.Memoize.put(key, out)
          unquote(name)(count, unquote_splicing(op_args))
      after unquote(timeout) ->
        unquote(loop)
      end
    end
  end
end