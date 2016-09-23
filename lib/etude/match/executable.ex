defmodule Etude.Match.Executable do
  defstruct [module: nil,
             function: :__execute__,
             env: nil]

  def execute(%{module: mod, function: fun, env: env}, bindings) do
    apply(mod, fun, [env, bindings])
  end

  def execute(%{module: mod, function: fun, env: env}, value, bindings) do
    apply(mod, fun, [env, value, bindings])
  end
end
