defmodule Etude.Template do
  defstruct name: nil,
            vsn: nil,
            line: 1,
            children: []

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
    name = template.name
    timeout = Keyword.get(opts, :timeout, 5000)

    function = Keyword.get(opts, :function, :render)

    opts = opts
    |> Keyword.put_new(:prefix, function)
    |> Keyword.put_new(:module, name)

    partial = "#{function}_partial" |> String.to_atom
    loop = "#{function}_loop" |> String.to_atom
    wait = "#{function}_wait" |> String.to_atom
    immediate = "#{function}_wait_immediate" |> String.to_atom

    root = Etude.Children.root(template.children, opts)

    children = template.children
    |> Etude.Children.compile(opts)
    |> Dict.values

    {function, [
    """
    #{file_line(template, opts)}
    -module(#{escape(name)}).
    #{version(template.vsn)}
    #{native(Keyword.get(opts, :native, false))}

    -export([#{function}/2, #{function}/3, #{partial}/5]).

    #{function}(State, Resolve) ->
      #{function}(State, Resolve, erlang:make_ref()).
    #{file_line(template, opts)}
    #{function}(State, Resolve, Req) ->
      #{debug(escape("init"), opts)},
      #{loop}(0, State, Resolve, Req, {0, 0}).

    #{partial}(#{op_args}, Args) ->
      #{debug(escape("init partial"), opts)},
      #{memo_put(Etude.Node.Prop.key(opts), 'Args')},
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

    etude_inspect(Val) ->
      'Elixir.Kernel':inspect(Val).
    """ | children]}
  end

  defp wait_block(name, timeout, loop) do
    """
    receive
      {ok, WaitVal, {Ref, ID}} when is_reference(Ref) ->
        Out = {#{ready}, WaitVal},
        #{memo_put('ID', 'Out', 'call')},
        #{name}(Count, #{op_args});
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

  def version(nil), do: ""
  def version(vsn), do: "-vsn(#{vsn})."
end