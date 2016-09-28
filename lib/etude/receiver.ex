defmodule Etude.Receiver do
  defstruct [handle_info: nil,
             cancel: &__MODULE__.__cancel__/2]

  @type state :: Etude.State.t
  @type status :: :ok | :error
  @type handler :: (handler_context, message :: term, state -> handler_return)
  @type handler_return :: :pass | {:cont, handler_context, state} | {status, any, state}
  @type handler_context :: any

  @type cancel :: (handler_context, state :: state -> state)

  @spec new(handler) :: %__MODULE__{}
  def new(handle_info) do
    %__MODULE__{handle_info: handle_info}
  end

  @spec new(handler, cancel) :: %__MODULE__{}
  def new(handle_info, cancel) do
    %__MODULE__{handle_info: handle_info, cancel: cancel}
  end

  def __cancel__(_, state) do
    state
  end
end
