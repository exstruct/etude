defmodule Expr do
  alias Expr.Template

  defmodule DSL do
    defmacro defexpr(qname, qchildren) do
      {name, _} = Code.eval_quoted(qname, __CALLER__.vars, __CALLER__)
      {children, _} = Code.eval_quoted(qchildren, __CALLER__.vars, __CALLER__)
      Expr.compile(name, children)
    end
  end

  defmacro __using__(_) do
    quote do
      require Logger
      import Expr.DSL
    end
  end

  def compile(name, children, opts \\ []) do
    template = %Template{name: name,
                         children: children}
    Template.compile(template, opts)
  end
end
