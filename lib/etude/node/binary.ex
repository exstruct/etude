defmodule Etude.Node.Binary do
  defstruct segments: [],
            line: nil
end

defmodule Etude.Node.Binary.Segment do
  defstruct type: nil,
            size: nil,
            signedness: nil,
            endianness: nil,
            unit: nil,
            expression: nil,
            line: nil

  def format_unit(%{unit: nil}), do: nil
  def format_unit(%{unit: unit}), do: "unit:#{unit}"

  def children(%{expression: expression, size: size}) do
    case size do
      nil ->
        [expression]
      size when is_integer(size) ->
        [expression]
      size ->
        [expression, size]
    end
  end

  def set_children(segment, [expression]) do
    %{segment | expression: expression}
  end
  def set_children(segment, [expression, size]) do
    %{segment | expression: expression, size: size}
  end

  def compile(%{expression: expression, size: size} = segment, opts) do
    var = Etude.Node.var(expression, opts)

    value = case size do
      nil ->
        var
      size when is_integer(size) ->
        "#{var}:#{size}"
      size ->
        size = Etude.Node.var(size, opts)
        "#{var}:#{size}"
    end

    specs = [segment.endianness,
             segment.signedness,
             segment.type,
             format_unit(segment)] |> Enum.filter(&(&1 != nil))

    case specs do
      [] ->
        value
      _ ->
        "#{value}/#{Enum.join(specs, "-")}"
    end
  end
end

defimpl Etude.Node, for: Etude.Node.Binary do
  alias Etude.Children
  import Etude.Vars
  import Etude.Utils

  defdelegate assign(node, opts), to: Etude.Node.Any
  defdelegate call(node, opts), to: Etude.Node.Any
  defdelegate name(node, opts), to: Etude.Node.Any
  defdelegate prop(node, opts), to: Etude.Node.Any
  defdelegate var(node, opts), to: Etude.Node.Any

  def compile(node, opts) do
    children = Enum.reduce(node.segments, [], fn(segment, acc) ->
      acc ++ Etude.Node.Binary.Segment.children(segment)
    end)
    name = Etude.Node.name(node, opts)
    exec = "#{name}_exec" |> String.to_atom

    defop node, opts, [:memoize], """
    #{Children.call(children, opts)},
    #{exec}(#{Children.vars(children, opts, ", ")}#{op_args})
    """, Dict.put(Etude.Children.compile(children, opts), exec, compile_exec(exec, node, children, opts))
  end

  defp compile_exec(name, node, children, opts) do
    segments = node.segments
    |> Enum.map(&(Etude.Node.Binary.Segment.compile(&1, opts)))
    |> Enum.join(", ")

    """
    #{file_line(node, opts)}
    #{name}(#{Children.args(children, opts, ", ")}#{op_args}) ->
      {{#{ready}, <<#{segments}>>}, #{state}};
    #{name}(#{Children.wildcard(children, opts, ", ")}#{op_args}) ->
      {nil, #{state}}.
    """
  end

  def pattern(_node, _opts) do
    throw "Binary matching is not implemented yet"
  end

  def children(node) do
    node.segments
    |> Enum.reduce([], fn(segment, acc) ->
      [Etude.Node.Binary.Segment.children(segment) | acc]
    end)
    |> :lists.reverse()
  end

  def set_children(node, children) do
    segments = node.segments
    |> :lists.zip(children)
    |> Enum.map(fn({segment, child}) ->
      Etude.Node.Binary.Segment.set_children(segment, child)
    end)
    %{node | segments: segments}
  end
end
