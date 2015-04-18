defmodule Expr.Utils do
  def ready do
    :EXPR_READY
  end

  def atom_to_var(name, context \\ nil) do
    {name, [], context}
  end
end