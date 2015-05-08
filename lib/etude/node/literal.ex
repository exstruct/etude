defmodule Etude.Node.Literal.Impl do
  defmacro __using__(_) do
    quote do
      defdelegate children(node), to: Etude.Node.Any
      defdelegate set_children(node, children), to: Etude.Node.Any
      defdelegate compile(node, opts), to: Etude.Node.Any

      def assign(node, opts) do
        "#{Etude.Node.var(node, opts)} = #{Etude.Node.call(node, opts)}"
      end

      def call(%Etude.Node.Literal{value: value}, opts) do
        call(value, opts)
      end
      def call(value, _opts) do
        "{#{Etude.Utils.ready}, #{Etude.Utils.escape(value)}}"
      end

      def prop(node, opts) do
        call(node, opts)
      end
    end
  end
end

defmodule Etude.Node.Literal do
  defstruct line: nil,
            value: nil

  defimpl Etude.Node, for: Etude.Node.Literal do
    defdelegate name(node, opts), to: Etude.Node.Any
    defdelegate var(node, opts), to: Etude.Node.Any
    use Etude.Node.Literal.Impl
  end
end