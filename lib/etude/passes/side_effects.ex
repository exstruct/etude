defmodule Etude.Passes.SideEffects do
  def transform(ast, _opts) do
    transform(ast, [], [])
  end

  defp transform([], assigns, _) do
    :lists.reverse(assigns)
  end
  defp transform([node], assigns, []) do
    transform([], [node | assigns], [])
  end
  defp transform([node], assigns, se) do
    call = %Etude.Node.Call{
      module: :erlang,
      function: :hd,
      arguments: [[node | :lists.reverse(se)]],
      attrs: %{
        native: true
      }
    }
    transform([], [call | assigns], [])
  end
  defp transform([%Etude.Node.Assign{} = node | rest], assigns, se) do
    transform(rest, [node | assigns], se)
  end
  defp transform([node | rest], assigns, se) do
    transform(rest, assigns, [node | se])
  end
end