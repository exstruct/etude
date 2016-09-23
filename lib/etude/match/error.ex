defmodule Etude.Match.Error do
  defexception [:term, :binding]

  def message(error) do
    MatchError.message(error)
  end
end
