defmodule Etude.Node.Call do
  defstruct module: nil,
            function: nil,
            arguments: [],
            attrs: %{},
            line: nil

  alias Etude.Children
  import Etude.Vars
  import Etude.Utils

  defimpl Etude.Node, for: Etude.Node.Call do
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

      etude_module = opts[:name] |> escape

      native = Etude.Utils.get_bin_or_atom(node.attrs, :native, false)

      defop node, opts, [:memoize], """
      #{Children.call(arguments, opts)},
      case #{exec}(#{Children.vars(arguments, opts, ", ")}#{op_args}) of
        nil ->
          #{debug('<<"#{name} deps pending">>', opts)},
          {nil, #{state}};
        pending ->
          #{debug('<<"#{name} call pending">>', opts)},
          {nil, #{state}};
        {partial, {PartialModule, PartialFunction, PartialProps} = Partial, rebind(#{state})} ->
          rebind(PartialProps) = 'Elixir.Enum':reduce(PartialProps, \#{}, fun({Key, Value}, Acc) -> maps:put(Key, {#{ready}, Value}, Acc) end),
          rebind(#{scope}) = {erlang:phash2({#{scope}, Partial}), 0},
          PartialModule:PartialFunction(#{op_args}, PartialProps);
        {partial, {PartialFunction, PartialProps}, rebind(#{state})} when is_atom(PartialFunction) ->
          rebind(PartialProps) = 'Elixir.Enum':reduce(PartialProps, \#{}, fun({Key, Value}, Acc) -> maps:put(Key, {#{ready}, Value}, Acc) end),
          rebind(#{scope}) = {erlang:phash2({#{scope}, {#{etude_module}, PartialFunction, PartialProps}}), 0},
          #{etude_module}:PartialFunction(#{op_args}, PartialProps);
        {ok, Value, rebind(#{state})} ->
          #{debug_res(name, "Value", "call", opts)},
          {Value, #{state}}
      end
      """, Dict.put(Children.compile(arguments, opts), exec, compile_exec(exec, native, node, opts))
    end

    defp compile_exec(name, native, node, opts) do
      mod = escape(node.module)
      fun = escape(node.function)
      arguments = node.arguments
      """
      #{file_line(node, opts)}
      #{name}(#{Children.args(arguments, opts, ", ")}#{op_args}) ->
        _Args = [#{Children.vars(arguments, opts)}],
        _ID = #{compile_mfa_hash(mod, fun, arguments, "_Args")},
        case #{memo_get('_ID', 'call')} of
          undefined ->
            #{debug_call(node.module, node.function, "_Args", opts)},
      #{indent(exec_block(mod, fun, arguments, native, node.attrs, opts), 2)};
          {partial, Partial} ->
            {partial, Partial, #{state}};
          {'__ETUDE_ERROR__', Error} ->
            erlang:error({'__ETUDE_ERROR__', Error, #{state}});
          Val ->
            {ok, Val, #{state}}
        end;
      #{name}(#{Children.wildcard(arguments, opts, ", ")}#{op_args}) ->
        nil.
      """
    end

    defp exec_block(mod, fun, arguments, true, _, opts) do
      """
        Val = {#{ready}, #{mod}:#{fun}(#{Children.vars(arguments, opts)})},
        #{memo_put('_ID', 'Val', 'call')},
        {ok, Val, #{state}}
      """
    end

    defp exec_block(mod, fun, _arguments, :hybrid, attrs, _opts) do
      """
        case #{mod}:#{fun}(_Args, #{state}, self(), {erlang:make_ref(), _ID}, #{escape(attrs)}) of
      #{exec_block_handle}
      """
    end

    defp exec_block(mod, fun, _arguments, _, attrs, _opts) do
      """
        case #{resolve}(#{mod}, #{fun}, _Args, #{state}, self(), {erlang:make_ref(), _ID}, #{escape(attrs)}) of
      #{exec_block_handle}
      """
    end

    defp exec_block_handle do
      """
          {ok, Pid} when is_pid(Pid) ->
            Ref = erlang:monitor(process, Pid),
            #{memo_put('_ID', 'Ref', 'call')},
            pending;
          {ok, Val} ->
            Out = {#{ready}, Val},
            #{memo_put('_ID', 'Out', 'call')},
            {ok, Out, #{state}};
          {ok, Val, NewState} ->
            Out = {#{ready}, Val},
            #{memo_put('_ID', 'Out', 'call')},
            {ok, Out, NewState};
          {partial, Partial} = PartialRes ->
            #{memo_put('_ID', 'PartialRes', 'call')},
            {partial, Partial, #{state}};
          {partial, Partial, NewState} ->
            Out = {partial, Partial},
            #{memo_put('_ID', 'Out', 'call')},
            {partial, Partial, NewState};
          {error, Error} ->
            erlang:error({'__ETUDE_ERROR__', Error, #{state}});
          {error, Error, NewState} ->
            erlang:error({'__ETUDE_ERROR__', Error, NewState})
        end;
      Ref when is_reference(Ref) ->
        pending
      """
    end
  end
end

defimpl Inspect, for: Etude.Node.Call do
  def inspect(node, _) do
    arguments = Enum.map(node.arguments, &inspect/1) |> Enum.join(", ")
    "#{node.module}.#{node.function}(#{arguments})"
  end
end
