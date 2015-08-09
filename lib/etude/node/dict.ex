defmodule Etude.Node.Dict do
  defstruct function: nil,
            arguments: [],
            line: nil
end

defmodule Etude.Node.Dict.UnsupportedFunction do
  defexception [:function]

  def message(%{function: function}) do
    "Etude.Dict.#{function} is not supported at this time"
  end
end

defimpl Etude.Node, for: Etude.Node.Dict do
  alias Etude.Children
  import Etude.Vars
  import Etude.Utils

  defdelegate assign(node, opts), to: Etude.Node.Any
  defdelegate call(node, opts), to: Etude.Node.Any
  defdelegate name(node, opts), to: Etude.Node.Any
  defdelegate pattern(node, opts), to: Etude.Node.Any
  defdelegate prop(node, opts), to: Etude.Node.Any
  defdelegate var(node, opts), to: Etude.Node.Any

  def children(node) do
    node.arguments
  end

  def set_children(node, arguments) do
    %{node | arguments: arguments}
  end

  def compile(node, opts) do
    name = Etude.Node.name(node, opts)
    arguments = node.arguments
    exec = "#{name}_exec" |> String.to_atom

    defop node, opts, [:memoize], """
    #{Children.call(arguments, opts)},
    case #{exec}(#{Children.vars(arguments, opts, ", ")}#{op_args}) of
      nil ->
        #{debug('<<"#{name} deps pending">>', opts)},
        {nil, #{state}};
      pending ->
        #{debug('<<"#{name} dict pending">>', opts)},
        {nil, #{state}};
      {ok, Value} ->
        #{debug_res(name, "Value", "dict", opts)},
        {Value, #{state}}
    end
    """, Dict.put(Children.compile(arguments, opts), exec, compile_exec(exec, node, opts))
  end

  defp compile_exec(name, %{function: function} = node, opts) do
    mod = escape(Etude.Dict)
    fun = escape(function)
    arguments = node.arguments
    [dict | other_args] = arguments

    dict_var = Etude.Node.var(dict, opts)

    """
    #{file_line(node, opts)}
    #{name}(#{Children.args(arguments, opts, ", ")}#{op_args}) ->
      _CacheKey = #{mod}:cache_key(#{dict_var}),
      rebind(#{dict_var}) = case #{memo_get('_CacheKey', 'dict')} of
        undefined -> #{dict_var};
        Prev -> Prev
      end,
      _CacheArgs = [_CacheKey | [#{Children.vars(other_args, opts)}]],
      _ID = #{compile_mfa_hash(mod, fun, arguments, "_CacheArgs")},
      case #{memo_get('_ID', 'dict')} of
        undefined ->
          #{debug_call(Etude.Dict, node.function, "_CacheArgs", opts)},
          OpRef = \#{'__struct__' => 'Elixir.Etude.Async', ref => {erlang:make_ref(), _ID, _CacheKey, dict}, parent => self()},
          case #{mod}:#{fun}(#{Children.vars(arguments, opts)}, OpRef) of
    #{indent(compile_clause(function), 4)}
          end;
        {'__ETUDE_ERROR__', Error} ->
          erlang:error({'__ETUDE_ERROR__', Error, #{state}});
        {'__ETUDE_PENDING__', _} ->
          pending;
        Val ->
          {ok, Val}
      end;
    #{name}(#{Children.wildcard(arguments, opts, ", ")}#{op_args}) ->
      nil.
    """
  end

  defp compile_clause(:fetch) do
    """
    {ok, Value, Fetched} ->
      #{memo_put('_CacheKey', 'Fetched', 'dict')},
      {ok, {#{ready}, {ok, Value}}};
    {error, Fetched} ->
      #{memo_put('_CacheKey', 'Fetched', 'dict')},
      {ok, {#{ready}, error}};
    #{compile_thunk_clauses()}
    """
  end

  # read-only
  defp compile_clause(function) when function in [:fetch!, :get, :has_key?, :keys, :size, :to_list, :values] do
    """
    {ok, Value, Fetched} ->
      #{memo_put('_CacheKey', 'Fetched', 'dict')},
      {ok, {#{ready}, Value}};
    #{compile_thunk_clauses()}
    """
  end

  # dict mutations
  defp compile_clause(function) when function in [:delete, :put, :put_new, :update] do
    """
    {ok, Value, Fetched} ->
      #{memo_put('_CacheKey', 'Fetched', 'dict')},
      MutatedValue = 'Etude.Dict.Mutation':wrap(Value, #{escape(function)}, tl(_CacheArgs)),
      #{memo_put("'Etude.Dict':cache_key(MutatedValue)", 'MutatedValue', 'dict')},
      {ok, {#{ready}, MutatedValue}};
    #{compile_thunk_clauses()}
    """
  end

  # unsupported
  defp compile_clause(function) do
    raise Etude.Node.Dict.UnsupportedFunction, function: function
  end

  defp compile_thunk_clauses() do
    """
    {error, Error, Fetched} ->
      #{memo_put('_CacheKey', 'Fetched', 'dict')},
      erlang:error({'__ETUDE_ERROR__', Error, #{state}});
    {pending, Fetched} ->
      #{memo_put('_CacheKey', 'Fetched', 'dict')},
      %#{memo_put('_ID', "{'__ETUDE_PENDING__', nil}", 'dict')},
      pending;
    {pending, Pid, Fetched} when is_pid(Pid) ->
      #{memo_put('_CacheKey', 'Fetched', 'dict')},
      Ref = erlang:monitor(process, Pid),
      #{memo_put('_ID', "{'__ETUDE_PENDING__', Ref}", 'dict')},
      put(Ref, {_ID, dict}),
      pending
    """
  end
end

defimpl Inspect, for: Etude.Node.Dict do
  def inspect(node, _) do
    arguments = Enum.map(node.arguments, &inspect/1) |> Enum.join(", ")
    "Etude.Dict.#{node.function}(#{arguments})"
  end
end
