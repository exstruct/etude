defmodule Etude.Utils do
  import Etude.Vars

  def ready do
    "'__ETUDE_READY__'"
  end

  def get_bin_or_atom(attrs, key, default \\ nil) do
    Dict.get(attrs, key, Dict.get(attrs, to_string(key), default))
  end

  def defop(node, opts, opopts, block, children \\ HashDict.new) do
    name = Etude.Node.name(node, opts)
    scope = Keyword.get(opopts, :scope, scope())
    should_memoize = :lists.member(:memoize, opopts)
    contents = """
    #{file_line(node, opts)}
    #{name}(#{op_args}) ->
    #{maybe_memoize(name, opts, block, scope, should_memoize)}
    """
    Dict.put(children, name, contents)
  end

  defp maybe_memoize(name, opts, block, scope, true) do
    """
      #{debug('<<"#{name} cache check">>', opts)},
      case #{memo_get(name, scope)} of
        undefined ->
          MemoRes = begin
    #{indent(block, 4)}
          end,
          case MemoRes of
            {nil, _} ->
              MemoRes;
            {MemoVal, _} ->
              #{debug_res(name, "MemoVal", "not cached", opts)},
              #{memo_put(name, "MemoVal", scope)},
              MemoRes
          end;
        CachedVal ->
          #{debug_res(name, "CachedVal", "cached", opts)},
          {CachedVal, #{state}}
      end.
    """
  end
  defp maybe_memoize(_name, _opts, block, _, _) do
    indent(block, 1) <> "."
  end

  def file_line(%{:line => nil}, _opts) do
    ""
  end
  def file_line(%{:__struct__ => _} = node, opts) do
    "-file(\"#{opts[:file]}\", #{node.line || 1})."
  end
  def file_line(_, opts) do
    "-file(\"#{opts[:file]}\", 1)."
  end

  def indent(block, indentations \\ 1) do
    block
    |> String.split("\n") |>
    Enum.map(fn(line) ->
      "#{Stream.cycle(["  "]) |> Enum.take(indentations) |> Enum.join("")}#{line}"
    end)
    |> Enum.join("\n")
  end

  def debug(code, opts) do
    if opts[:debug] do
      ~s{io:put_chars([<<"DEBUG | ">>, <<" #{opts[:name]} :: ">>, #{code}, <<"\\n">>])}
    else
      "false"
    end
  end

  def memo_get(key, s \\ scope) do
    "get({#{req}, #{s}, #{key}})"
  end
  def memo_delete(key, s \\ scope) do
    "erase({#{req}, #{s}, #{key}})"
  end
  def memo_put(key, value, s \\ scope) do
    "put({#{req}, #{s}, #{key}}, #{value})"
  end

  def debug_res(name, val, message \\ "result", opts) do
    debug("[<<\"#{name} #{message} -> \">>, etude_inspect(element(2, #{val})), <<\" (scope \">>, etude_inspect(#{scope}), <<\")\">>]", opts)
  end

  def debug_call(mod, fun, args_var, opts) when is_atom(mod) do
    debug_call(escape(mod), fun, args_var, opts)
  end
  def debug_call(mod, fun, args_var, opts) when is_atom(fun) do
    debug_call(mod, escape(fun), args_var, opts)
  end
  def debug_call(mod, fun, args_var, opts) do
    str = "[<<\"calling \">>, 'Elixir.String.Chars':to_string(#{mod}), <<\".\">>, 'Elixir.String.Chars':to_string(#{fun}), <<\"(\">>, 'Elixir.Enum':join('Elixir.Enum':map(#{args_var}, fun etude_inspect/1), <<\", \">>), <<\")\">>]"
    debug(str, opts)
  end

  def inline(name, arity) do
    "-compile({inline, #{name}/#{arity}})."
  end

  def escape(val) do
    :io_lib.format("~p", [val])
  end

  def compile_mfa_hash(mod, fun, [], _) do
    Etude.Runtime.hash({mod, fun, []})
  end
  def compile_mfa_hash(mod, fun, _, args) do
    "'Elixir.Etude.Runtime':hash({#{mod}, #{fun}, #{args}})"
  end

  def wildcard(n) when is_integer(n) do
    wildcard(1..n)
  end
  def wildcard(collection) do
    collection
    |> Enum.map(fn(_) ->
      "_"
    end)
    |> Enum.join(", ")
  end
end
