defmodule Etude.Node.Prop do
  defstruct name: nil,
            line: nil

  import Etude.Utils
  import Etude.Vars

  defimpl Etude.Node, for: Etude.Node.Prop do
    defdelegate assign(node, opts), to: Etude.Node.Any
    defdelegate children(node), to: Etude.Node.Any
    defdelegate set_children(node, children), to: Etude.Node.Any
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate prop(node, opts), to: Etude.Node.Any
    defdelegate var(node, opts), to: Etude.Node.Any

    def compile(_, _) do
      {:etude_props, """
      etude_props(Props, Key, State) ->
        case etude_props_exec(Props, Key) of
          Fun when is_function(Fun) ->
            Fun(State);
          Val ->
            {Val, State}
        end.

      etude_props_exec(Props, Key) when is_map(Props) ->
        maps:get(Key, Props, {#{ready}, undefined});
      etude_props_exec(_Props, _Key) ->
        {#{ready}, undefined}.
      """}
    end

    def call(node, opts) do
      "etude_props(#{memo_get(Etude.Node.Prop.key(opts), Etude.Node.Prop.scope)}, #{escape(node.name)}, #{state})"
    end
  end

  def key(opts) do
    "{#{escape(opts[:module])}, '__PROPS__'}"
  end

  def scope do
    "element(1, #{Etude.Vars.scope})"
  end
end

defimpl Inspect, for: Etude.Node.Prop do
  def inspect(node, _) do
    "$#{node.name}"
  end
end