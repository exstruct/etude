defmodule Etude.Node.Prop do
  defstruct name: nil,
            line: nil

  import Etude.Utils
  import Etude.Vars

  defimpl Etude.Node, for: Etude.Node.Prop do
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate assign(node, context), to: Etude.Node.Any
    defdelegate var(node, context), to: Etude.Node.Any
    defdelegate prop(node, opts), to: Etude.Node.Any

    def compile(_, _) do
      {:etude_props, """
      etude_props(Props, Key) ->
        case etude_props_exec(Props, Key) of
          Fun when is_function(Fun) ->
            Fun;
          Val ->
            fun (State) -> {Val, State} end
        end.

      etude_props_exec(Props, Key) when is_map(Props) ->
        maps:get(Key, Props, undefined);
      etude_props_exec(_Props, _Key) ->
        {#{ready}, undefined}.
      """}
    end

    def call(node, _opts) do
      "(etude_props(?MEMO_GET(#{req}, {?MODULE, '__ARGV__'}, #{scope}), #{node.name}))(#{state})"
    end
  end
end