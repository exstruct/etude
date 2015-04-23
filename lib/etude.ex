defmodule Etude do
  alias Etude.Template

  defmodule DSL do
    defmacro defetude(qname, qchildren) do
      {name, _} = Code.eval_quoted(qname, __CALLER__.vars, __CALLER__)
      {children, _} = Code.eval_quoted(qchildren, __CALLER__.vars, __CALLER__)
      Etude.compile(name, children)
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
              children: transform_children(children)}
    |> Template.compile(opts)
  end

  defp transform_children(children, opts) do
    children
    |> Etude.Passes.SideEffects.transform(opts)
  end
end
