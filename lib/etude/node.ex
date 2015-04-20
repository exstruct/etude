defprotocol Etude.Node do
  @fallback_to_any true

  def name(node, opts)
  def compile(node, opts)
  def call(node, opts)
  def assign(node, opts)
  def var(node, opts)
end

defimpl Etude.Node, for: [Atom, BitString, Integer, Float] do
  defdelegate name(node, opts), to: Etude.Node.Any
  defdelegate var(node, opts), to: Etude.Node.Any

  def compile(_, _) do
    []
  end

  def call(value, _) do
    Macro.escape({Etude.Utils.ready, value})
  end

  def assign(value, opts) do
    quote do
      unquote(Etude.Node.var(value, opts)) = unquote(Etude.Node.call(value, opts))
    end
  end
end

defimpl Etude.Node, for: Any do
  import Etude.Vars

  def name(node, opts) do
    prefix = Keyword.get(opts, :prefix)
    "#{prefix}_#{:erlang.phash2(node)}"
    |> String.to_atom
  end

  def compile(_, _) do
    []
  end

  def call(node, opts) do
    quote do
      unquote(Etude.Node.name(node, opts))(unquote_splicing(op_args))
    end
  end

  def assign(node, opts) do
    quote do
      {unquote(Etude.Node.var(node, opts)), unquote(state)} = unquote(Etude.Node.call(node, opts))
    end
  end

  def var(node, opts) do
    Macro.var(Etude.Node.name(node, opts), nil)
  end
end