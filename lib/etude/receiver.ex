defmodule Etude.Receiver do
  defstruct [handle_info: nil,
             cancel: &__MODULE__.__cancel__/2]

  def __cancel__(_, state) do
    state
  end
end
