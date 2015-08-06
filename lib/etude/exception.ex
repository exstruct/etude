defmodule Etude.Exception do
  defexception [:state, :error]

  def message(%{error: error}) when is_atom(error) or is_binary(error) do
    to_string(error)
  end
  def message(%{error: error}) do
    inspect(error)
  end
end
