defmodule Etude do
  alias Etude.Codegen
  alias Etude.Template

  @vsn Mix.Project.config[:version]

  defmacro __using__(_) do
    quote do
      import Etude.DSL
    end
  end

  def compile(name, children, opts \\ []) do
    opts = defaults(name, opts)
    init_template(name, children, opts)
    |> compile_template(opts)
    |> codegen(opts)
  end

  def compile_lazy(name, children, opts \\ []) do
    opts = defaults(name, opts)
    template = init_template(name, children, opts)
    {template.version, fn() ->
      template
      |> compile_template(opts)
      |> codegen(opts)
    end}
  end

  defp defaults(name, opts) do
    opts
    |> Keyword.put_new(:file, "")
    |> Keyword.put_new(:erlc_options, [])
    |> Keyword.put_new(:main, opts[:function] || :render)
    |> Keyword.put_new(:name, name)
  end

  defp init_template(name, children, opts) do
    children = transform_children(children, opts)
    %Template{name: name,
              version: :erlang.phash2({@vsn, children}),
              children: children}
  end

  defp compile_template(template, opts) do
    Template.compile(template, opts)
  end

  defp transform_children(children, opts) do
    children
    |> Etude.Passes.Scopes.transform(opts)
    |> Etude.Passes.SideEffects.transform(opts)
  end

  defp codegen(input, opts) do
    input
    |> Codegen.to_forms(opts)
    |> Codegen.to_beam(opts)
  end
end
