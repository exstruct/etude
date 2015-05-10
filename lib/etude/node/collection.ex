defmodule Etude.Node.Collection do
  alias Etude.Children
  import Etude.Vars
  import Etude.Utils

  defprotocol Construction do
    def construct(node, vars)  
  end

  def compile(node, opts) do
    name = Etude.Node.name(node, opts)
    exec = "#{name}_exec" |> String.to_atom

    defop node, opts, [:memoize, :inline], """
    #{Children.call(node, opts)},
    case #{exec}(#{Children.vars(node, opts)}) of
      nil ->
        #{debug('<<"#{name} deps pending">>', opts)},
        {nil, #{state}};
      CollVal ->
        #{debug_res(name, "CollVal", "collection", opts)},
        {CollVal, #{state}}
    end
    """, Dict.put(Children.compile(node, opts), exec, compile_exec(exec, node, opts))
  end

  defp compile_exec(name, node, opts) do
    case Children.count(node) do
      0 ->
        compile_exec_def(name, 0, node, opts, ".")
      count ->
        """
        #{file_line(node, opts)}
        #{compile_exec_def(name, count, node, opts, ";")}
        #{name}(#{Children.wildcard(node, opts)}) ->
          nil.
        """
    end
  end

  def compile_exec_def(name, count, node, opts, ending) do
    construction = Construction.construct(node, Children.vars(node, opts))
    """
    #{file_line(node, opts)}
    #{inline(name, count)}
    #{name}(#{Children.args(node, opts)}) ->
      {#{ready},
    #{indent(construction, 2)}}#{ending}
    """
  end
end