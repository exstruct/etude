defmodule Etude.Vars do
  def state(context \\ nil) do
    Macro.var(:_state, context)
  end
  def resolve(context \\ nil) do
    Macro.var(:_resolve, context)
  end
  def req(context \\ nil) do
    Macro.var(:_req, context)
  end
  def scope(context \\ nil) do
    Macro.var(:_scope, context)
  end

  def op_args(context \\ nil) do
    [state(context), resolve(context), req(context), scope(context)]
  end

  def child_scope(name, context \\ nil)
  def child_scope(name, context) when is_atom(name) do
    child_scope(Macro.var(name, context), context)
  end
  def child_scope(vars, _context) do
    quote do
      unquote(scope) = :erlang.phash2({unquote(scope), unquote(vars)})
    end
  end
end