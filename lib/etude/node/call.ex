defmodule Etude.Node.Call do
  defstruct module: nil,
            function: nil,
            arguments: [],
            attrs: %{},
            line: 1

  alias Etude.Children
  import Etude.Vars

  defimpl Etude.Node, for: Etude.Node.Call do
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate call(node, opts), to: Etude.Node.Any
    defdelegate assign(node, opts), to: Etude.Node.Any
    defdelegate var(node, opts), to: Etude.Node.Any

    def compile(node, opts) do
      name = Etude.Node.name(node, opts)
      arguments = node.arguments
      exec = "#{name}_exec" |> String.to_atom

      native = Etude.Utils.get_bin_or_atom(node.attrs, :native, false)

      quote line: node.line do
        ## after running some benchmarks inlining doesn't help much here
        @compile {:nowarn_unused_function, {unquote(name), unquote(length(op_args))}}
        defp unquote(name)(unquote_splicing(op_args)) do
          Etude.Memoize.wrap unquote(name) do
            ## dependencies
            unquote_splicing(Children.call(arguments, opts))

            ## exec
            case unquote(exec)(unquote_splicing(Children.vars(arguments, opts)), unquote_splicing(op_args)) do
              nil ->
                Logger.debug(unquote("#{name} deps pending"))
                {nil, unquote(state)}
              :pending ->
                Logger.debug(unquote("#{name} call pending"))
                {nil, unquote(state)}
              {val, state} ->
                Logger.debug(fn -> unquote("#{name} result -> ") <> inspect(elem(val, 1)) end)
                {val, state}
            end
          end
        end

        unquote(compile_exec(exec, native, node, opts))
        defp unquote(exec)(unquote_splicing(Children.wildcard(arguments, opts)), unquote_splicing(op_args)) do
          nil
        end

        unquote_splicing(Children.compile(arguments, opts))
      end
    end

    defp compile_exec(name, true, node, opts) do
      mod = node.module
      fun = node.function
      arguments = node.arguments
      args = Macro.var(:args, nil)

      quote do
        defp unquote(name)(unquote_splicing(Children.args(arguments, opts)), unquote_splicing(op_args)) do
          unquote(args) = unquote(Children.vars(arguments, opts))
          id = unquote(Etude.Node.Call.compile_id_hash(mod, fun, arguments))
          case Etude.Memoize.get(id, scope: :call) do
            :undefined ->
              Logger.debug(fn ->
                unquote("calling #{mod}.#{fun}(") <>
                  (Enum.map(unquote(args), &inspect/1) |> Enum.join(", ")) <> ")"
              end)
              val = unquote(mod).unquote(fun)(unquote_splicing(Children.vars(arguments, opts)))
              {{unquote(Etude.Utils.ready), val}, unquote(state)}
            val ->
              {val, unquote(state)}
          end
        end
      end
    end

    defp compile_exec(name, _native, node, opts) do
      mod = node.module
      fun = node.function
      arguments = node.arguments
      attrs = Macro.escape(node.attrs)
      args = Macro.var(:args, nil)

      quote do
        defp unquote(name)(unquote_splicing(Children.args(arguments, opts)), unquote_splicing(op_args)) do
          unquote(args) = unquote(Children.vars(arguments, opts))
          id = unquote(Etude.Node.Call.compile_id_hash(mod, fun, arguments))
          case Etude.Memoize.get(id, scope: :call) do
            :undefined ->
              Logger.debug(fn ->
                unquote("calling #{mod}.#{fun}(") <>
                  (Enum.map(unquote(args), &inspect/1) |> Enum.join(", ")) <> ")"
              end)
              case unquote(resolve).(unquote(mod),
                                     unquote(fun),
                                     unquote(args),
                                     unquote(state),
                                     self(),
                                     {:erlang.make_ref(), id},
                                     unquote(attrs)) do
                ## TODO handle pids
                {:ok, pid} when is_pid(pid) ->
                  ref = :erlang.monitor(:process, pid)
                  Etude.Memoize.put(id, ref, scope: :call)
                  :pending
                {:ok, val} ->
                  out = {unquote(Etude.Utils.ready), val}
                  Etude.Memoize.put(id, out, scope: :call)
                  {out, unquote(state)}
                {:ok, val, state} ->
                  out = {unquote(Etude.Utils.ready), val}
                  Etude.Memoize.put(id, out, scope: :call)
                  {out, state}
              end
            ref when is_reference(ref) ->
              :pending
            val ->
              {val, unquote(state)}
          end
        end
      end
    end
  end

  def compile_id_hash(mod, fun, []) do
    :erlang.phash2({mod, fun, []})
  end
  def compile_id_hash(mod, fun, _) do
    quote do
      :erlang.phash2({unquote(mod), unquote(fun), unquote(Macro.var(:args, nil))})
    end
  end
end