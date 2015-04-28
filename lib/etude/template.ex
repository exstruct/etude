defmodule Etude.Template do
  defstruct name: nil,
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

    opts = Keyword.put_new(opts, :prefix, function)

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
    -module(#{name}).
    -compile(native).
    -compile({hipe, [o3]}).
    -compile({parse_transform, rebind}).
    -compile({parse_transform, lineo}).

    %% TODO expose as an option
    %-define(DEBUG(Str), io:put_chars([<<"DEBUG | ">>, ?FILE, <<":">>, integer_to_list(?LINE), <<" :: ">>, Str, <<"\\n">>])).
    -define(DEBUG(_Str), nil).
    -define(INSPECT, fun(Val) -> ?INSPECT(Val) end).
    -define(INSPECT(Val), 'Elixir.Kernel':inspect(Val)).
    -define(MEMO_GET(Req, Key, Scope), get({Req, Key, Scope})).
    -define(MEMO_PUT(Req, Key, Scope, Value), put({Req, Key, Scope}, Value)).

    -export([#{function}/2, #{function}/3, #{partial}/5]).

    #{file_line(template, opts)}
    #{function}(State, Resolve) ->
      #{function}(State, Resolve, erlang:make_ref()).
    #{file_line(template, opts)}
    #{function}(State, Resolve, Req) ->
      ?DEBUG(<<"init">>),
      #{loop}(0, State, Resolve, Req, 0).

    #{partial}(#{op_args}, Args) ->
      ?DEBUG([<<"init partial">>]),
      ?MEMO_PUT(#{req}, {?MODULE, '__ARGV__'}, #{scope}, Args),
      case #{root} of
        {{#{ready}, _} = PartialVal, NewState} ->
          {PartialVal, NewState};
        {#{ready}, _} = PartialVal ->
          {PartialVal, #{state}};
        Other ->
          Other
      end.

    #{loop}(Count, #{op_args}) ->
      ?DEBUG([<<"loop (">>, ?INSPECT(Count), <<")">>]),
      case #{root} of
        {{#{ready}, LoopVal}, NewState} ->
          {LoopVal, NewState};
        {#{ready}, LoopVal} ->
          {LoopVal, #{state}};
        {nil, NewState} ->
          #{wait}(Count + 1, NewState, #{resolve}, #{req}, #{scope})
      end.

    #{wait}(Count, #{op_args}) ->
      ?DEBUG([<<"wait (">>, ?INSPECT(Count), <<")">>]),
    #{indent(wait_block(immediate, timeout, "{error, timeout, #{state}}"), 1)}.

    #{immediate}(Count, #{op_args}) ->
      ?DEBUG([<<"wait[immediate] (">>, ?INSPECT(Count), <<")">>]),
    #{indent(wait_block(immediate, 0, "#{loop}(Count, #{op_args})"), 1)}.
    """ | children]}
  end

  defp wait_block(name, timeout, loop) do
    """
    receive
      {ok, WaitVal, {Ref, ID}} when is_reference(Ref) ->
        Out = {#{ready}, WaitVal},
        ?MEMO_PUT(#{req}, ID, call, Out),
        #{name}(Count, #{op_args});
      {'DOWN', _Ref, process, _Pid, normal} ->
        #{name}(Count, #{op_args})
    after #{timeout} ->
      #{loop}
    end
    """
  end
end