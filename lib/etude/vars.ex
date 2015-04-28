defmodule Etude.Vars do
  def state do
    "_State"
  end
  def resolve do
    "_Resolve"
  end
  def req do
    "_Req"
  end
  def scope do
    "_Scope"
  end

  def inspect do
    "?INSPECT"
  end

  def op_args(state_var \\ state) do
    [state_var, resolve, req, scope] |> Enum.join(", ")
  end

  def op_args_length do
    4
  end

  def child_scope(name)
  def child_scope(name) when is_list(name) do
    child_scope(Enum.join(name, ", "))
  end
  def child_scope(vars) do
    "rebind(#{scope}) = erlang:phash2({#{scope}, #{vars}})"
  end
end