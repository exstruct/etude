defmodule Etude.Thunk.Continuation do
  defstruct function: nil,
            arguments: []
end

defimpl Etude.Thunk, for: Etude.Thunk.Continuation do
  def resolve(%{function: function, arguments: arguments}, state) when is_function(function) do
    function.(arguments, state)
  end
end
