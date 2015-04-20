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
    template = %Template{name: name,
                         children: children}
    Template.compile(template, opts)
  end
end
