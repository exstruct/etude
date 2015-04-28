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
    contents = """
    #{file_line(node, opts)}
    #{name}(#{op_args}) ->
    #{maybe_memoize(name, opts, block, :lists.member(:memoize, opopts))}
    """
    Dict.put(children, name, contents)
  end

  defp maybe_memoize(name, _opts, block, true) do
    """
      ?DEBUG(<<"#{name} cache check">>),
      case ?MEMO_GET(#{req}, #{name}, #{scope}) of
        undefined ->
          MEMO_RES = begin
    #{indent(block, 4)}
          end,
          case MEMO_RES of
            {nil, _} ->
              MEMO_RES;
            {MemoVal, _} ->
              ?MEMO_PUT(#{req}, #{name}, #{scope}, MemoVal),
              MEMO_RES
          end;
        CachedVal ->
          #{debug_res(name, "CachedVal", "cached")},
          {CachedVal, #{state}}
      end.
    """
  end
  defp maybe_memoize(_name, _opts, block, _) do
    indent(block, 1) <> "."
  end

  def file_line(%{:line => nil} = node, opts) do
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

  def debug_res(name, val, message \\ "result") do
    "?DEBUG([<<\"#{name} #{message} -> \">>, ?INSPECT(element(2, #{val})), <<\" (scope \">>, ?INSPECT(#{scope}), <<\")\">>])"
  end

  def debug_call(mod, fun, args_var) do
    "?DEBUG([<<\"calling #{mod}.#{fun}(\">>, 'Elixir.Enum':join('Elixir.Enum':map(#{args_var}, ?INSPECT), <<\", \">>), <<\")\">>])"
  end

  def inline(name, arity) do
    "-compile({inline, #{name}/#{arity}})."
  end

  def escape(val) do
    :io_lib.format("~p", [val])
  end

  def compile_mfa_hash(mod, fun, [], _) do
    :erlang.phash2({mod, fun, []})
  end
  def compile_mfa_hash(mod, fun, _, args) do
    "erlang:phash2({#{mod}, #{fun}, #{args}})"
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