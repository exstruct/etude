defmodule Etude.Vars do
  alias Etude.Utils

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

  def child_scope(name, mode \\ :isolate)
  def child_scope(name, mode) when is_list(name) do
    child_scope(Enum.join(name, ", "), mode)
  end
  def child_scope(vars, :isolate) do
    """
    rebind(#{scope}) = {{#{scope}, #{escape(vars)}}, 0}
    """
  end
  def child_scope(vars, :inherit) do
    """
    {rebind(_Scope_Namespace), rebind(_Scope_Child)} = #{scope},
    rebind(#{scope}) = {_Scope_Namespace, {_Scope_Child, #{escape(vars)}}}
    """
  end

  defp escape(vars) when is_binary(vars) do
    vars
  end
  defp escape(vars) do
    Utils.escape(vars)
  end
end
