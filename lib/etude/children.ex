defmodule Etude.Children do
  alias Etude.Utils
  import Etude.Vars

  def compile(children, opts) when is_tuple(children) do
    compile(Tuple.to_list(children), opts)
  end
  def compile(children, opts) do
    Enum.reduce(children, [], fn(child, acc) ->
      case Etude.Node.compile(child, opts) do
        ast when is_list(ast) ->
          acc ++ ast
        {:__block__, _, ast} ->
          acc ++ ast
        ast ->
          acc ++ [ast]
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
        quote do
          {{unquote(Utils.ready), nil}, unquote(state)}
        end
      child ->
        Etude.Node.call(child, opts)
    end
  end

  def call(children, opts) when is_tuple(children) do
    call(Tuple.to_list(children), opts)
  end
  def call(children, opts) do
    Enum.map(children, fn(child) ->
      Etude.Node.assign(child, opts)
    end)
  end

  def vars(children, opts) when is_tuple(children) do
    vars(Tuple.to_list(children), opts)
  end
  def vars(children, opts) do
    Enum.map(children, fn(child) ->
      Etude.Node.var(child, opts)
    end)
  end

  def args(children, opts) when is_tuple(children) do
    args(Tuple.to_list(children), opts)
  end
  def args(children, opts) do
    Enum.map(children, fn(child) ->
      quote do
        {unquote(Utils.ready), unquote(Etude.Node.var(child, opts))}
      end
    end)
  end

  def wildcard(children, opts) when is_tuple(children) do
    wildcard(Tuple.to_list(children), opts)
  end
  def wildcard(children, _opts) do
    Enum.map(children, fn(_) -> Macro.var(:_, nil) end)
  end
end