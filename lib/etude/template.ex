defmodule Etude.Template do
  defstruct name: nil,
            version: nil,
            children: [],
            line: 1

  import Etude.Utils
  import Etude.Vars

  defimpl String.Chars, for: Etude.Template do
    def to_string(template) do
      template
      |> Etude.Template.compile
      |> Kernel.to_string
    end
  end

  def compile(template, opts \\ []) do
    [head(template, opts),
     Enum.map(template.children, &(main_block(&1, opts))),
     Enum.reduce(template.children, %{}, fn({_, children}, acc) ->
      children
      |> Etude.Children.compile(opts)
      |> Dict.merge(acc)
     end) |> Dict.values]
  end

  defp head(template, opts) do
    """
    #{file_line(template, opts)}
    -module(#{escape(template.name)}).
    -vsn(#{template.version}).

    #{exports(template, opts)}

    #{native(Keyword.get(opts, :native, false))}

    etude_inspect(Val) ->
      'Elixir.Kernel':inspect(Val).
    """
  end

  defp exports(template, _opts) do
    Enum.map(template.children, fn({name, _ast}) ->
      partial = "#{name}_partial" |> String.to_atom |> escape
      name = name |> to_string |> String.to_atom |> escape
      "-export([#{name}/2, #{name}/3, #{partial}/5]).\n"
    end)
  end

  defp main_block({name, children}, opts) do
    timeout = Keyword.get(opts, :timeout, 10_000)

    partial = "#{name}_partial" |> String.to_atom |> escape
    loop = "#{name}_loop" |> String.to_atom |> escape
    wait = "#{name}_wait" |> String.to_atom |> escape
    immediate = "#{name}_wait_immediate" |> String.to_atom |> escape
    name = name |> to_string |> String.to_atom |> escape

    root = Etude.Children.root(children, opts)

    """
    #{name}(State, Resolve) ->
      #{name}(State, Resolve, erlang:make_ref()).
    #{name}(State, Resolve, Req) ->
      #{debug(escape("init"), opts)},
      #{loop}(0, State, Resolve, Req, {0, 0}).

    #{partial}(#{op_args}, Props) ->
      #{debug(escape("init partial"), opts)},
      #{memo_put(Etude.Node.Prop.key(opts), 'Props', Etude.Node.Prop.scope)},
      case #{root} of
        {{#{ready}, _} = PartialVal, NewState} ->
          {PartialVal, NewState};
        {#{ready}, _} = PartialVal ->
          {PartialVal, #{state}};
        Other ->
          Other
      end.

    #{loop}(Count, #{op_args}) ->
      #{debug('[<<"loop (">>, etude_inspect(Count), <<")">>]', opts)},
      case #{root} of
        {{#{ready}, LoopVal}, NewState} ->
          {LoopVal, NewState};
        {#{ready}, LoopVal} ->
          {LoopVal, #{state}};
        {nil, NewState} ->
          #{wait}(Count + 1, NewState, #{resolve}, #{req}, #{scope})
      end.

    #{wait}(Count, #{op_args}) ->
      #{debug('[<<"wait (">>, etude_inspect(Count), <<")">>]', opts)},
    #{indent(wait_block(immediate, timeout, "{error, timeout, #{state}}"), 1)}.

    #{immediate}(Count, #{op_args}) ->
      #{debug('[<<"wait[immediate] (">>, etude_inspect(Count), <<")">>]', opts)},
    #{indent(wait_block(immediate, 0, "#{loop}(Count, #{op_args})"), 1)}.
    """
  end

  defp wait_block(name, timeout, loop) do
    """
    receive
      {ok, WaitVal, {Ref, ID}} when is_reference(Ref) ->
        Out = {#{ready}, WaitVal},
        #{memo_put('ID', 'Out', 'call')},
        #{name}(Count, #{op_args});
      {error, Error, {Ref, ID}} when is_reference(Ref) ->
        throw({Error, #{state}});
      {'DOWN', _Ref, process, _Pid, normal} ->
        #{name}(Count, #{op_args})
    after #{timeout} ->
      #{loop}
    end
    """
  end

  defp native(true) do
    """
    -compile(native).
    -compile({hipe, [o3]}).
    """
  end
  defp native(_) do
    ""
  end
end