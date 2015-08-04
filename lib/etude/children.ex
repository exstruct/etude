defmodule Etude.Children do
  alias Etude.Node
  alias Etude.Utils
  import Etude.Vars

  def compile(children, opts) when is_tuple(children) do
    compile(Tuple.to_list(children), opts)
  end
  def compile(children, opts) do
    Enum.reduce(children, HashDict.new, fn(child, acc) ->
      case Node.compile(child, opts) do
        nil ->
          acc
        {name, contents} ->
          Dict.put(acc, name, contents)
        funs ->
          Dict.merge(funs, acc)
      end
    end)
  end

  def count(children) when is_tuple(children) do
    :erlang.tuple_size(children)
  end
  def count(children) do
    Enum.count(children)
  end

  def root(children, opts) do
    case List.last(children) do
      nil ->
        "{{#{Utils.ready}, nil}, #{state}}"
      child ->
        Node.call(child, opts)
    end
  end

  def call(children, opts) when is_tuple(children) do
    call(Tuple.to_list(children), opts)
  end
  def call(node, opts) when node in [[], %{}, {}] do
    "#{Node.var(node, opts)} = #{Utils.escape(node)}"
  end
  def call(children, opts) do
    children
    |> Enum.map(&(Node.assign(&1, opts)))
    |> Enum.uniq
    |> Enum.join(",\n")
  end

  def vars(children, opts, ending \\ "")
  def vars(children, opts, ending) when is_tuple(children) do
    vars(Tuple.to_list(children), opts, ending)
  end
  def vars([], _, _) do
    ""
  end
  def vars(children, opts, ending) do
    out = Enum.map(children, fn(child) ->
      Node.var(child, opts)
    end) |> Enum.join(", ")
    out <> ending
  end

  def props(children, opts) when is_tuple(children) do
    props(Tuple.to_list(children), opts)
  end
  def props(children, opts) do
    out = Enum.map(children, fn({key, value}) ->
      "#{Utils.escape(key)} => #{Node.prop(value, opts)}"
    end) |> Enum.join(", ")
    "\#{#{out}}"
  end

  def args(children, opts, ending \\ "")
  def args(children, opts, ending) when is_tuple(children) do
    args(Tuple.to_list(children), opts, ending)
  end
  def args([], _, _) do
    ""
  end
  def args(children, opts, ending) do
    out = Enum.map(children, fn(child) ->
      "{#{Utils.ready}, #{Node.var(child, opts)}}"
    end) |> Enum.join(", ")
    out <> ending
  end

  def wildcard(children, opts, ending \\ "")
  def wildcard(children, opts, ending) when is_tuple(children) do
    wildcard(Tuple.to_list(children), opts, ending)
  end
  def wildcard([], _, _) do
    ""
  end
  def wildcard(children, _opts, ending) do
    Utils.wildcard(children) <> ending
  end

  def map(children, fun) when is_tuple(children) do
    Tuple.to_list(children)
    |> map(fun)
  end
  def map(children, fun) do
    Enum.map(children, fun)
  end
end
