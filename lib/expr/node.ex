defprotocol Expr.Node do
  @fallback_to_any true

  def name(node, opts)
  def compile(node, opts)
  def call(node, opts)
  def assign(node, opts)
  def var(node, opts)
end

defimpl Expr.Node, for: [Atom, BitString, Integer, Float] do
  defdelegate name(node, opts), to: Expr.Node.Any
  defdelegate var(node, opts), to: Expr.Node.Any

  def compile(_, _) do
    []
  end

  def call(value, _) do
    Macro.escape({Expr.Utils.ready, value})
  end

  def assign(value, opts) do
    quote do
      unquote(Expr.Node.var(value, opts)) = unquote(Expr.Node.call(value, opts))
    end
  end
end

defimpl Expr.Node, for: Any do
  import Expr.Vars

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
      unquote(Expr.Node.name(node, opts))(unquote_splicing(op_args))
    end
  end

  def assign(node, opts) do
    quote do
      {unquote(Expr.Node.var(node, opts)), unquote(state)} = unquote(Expr.Node.call(node, opts))
    end
  end

  def var(node, opts) do
    Expr.Utils.atom_to_var(Expr.Node.name(node, opts))
  end
end