defprotocol Etude.Node do
  @fallback_to_any true

  def name(node, opts)
  def compile(node, opts)
  def call(node, opts)
  def assign(node, opts)
  def prop(node, opts)
  def var(node, opts)
end

defimpl Etude.Node, for: [Atom, BitString, Integer, Float] do
  defdelegate name(node, opts), to: Etude.Node.Any
  defdelegate var(node, opts), to: Etude.Node.Any
  use Etude.Node.Literal.Impl
end

defimpl Etude.Node, for: Any do
  import Etude.Vars

  def name(node, opts) when is_map(node) do
    id = node
    |> Map.to_list
    |> List.keysort(0)
    name(id, opts)
  end
  def name(node, opts) do
    prefix = Keyword.get(opts, :prefix)
    "#{prefix}_#{:erlang.phash2(node)}"
    |> String.to_atom
  end

  def compile(_, _) do
    nil
  end

  def call(node, opts) do
    "#{Etude.Node.name(node, opts)}(#{op_args})"
  end

  def prop(node, opts) do
    "fun (rebind(#{state})) -> #{Etude.Node.call(node, opts)} end"
  end

  def assign(node, opts) do
    "{#{Etude.Node.var(node, opts)}, rebind(#{state})} = #{Etude.Node.call(node, opts)}"
  end

  def var(node, opts) do
    "_val_#{Etude.Node.name(node, opts)}"
  end
end