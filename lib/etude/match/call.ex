defmodule Etude.Match.Call do
  defstruct [:fun, :args]

  defimpl Etude.Matchable do
    alias Etude.Thunk.RemoteApplication

    def compile(call) do
      throw {:invalid_call, call}
    end

    def compile_body(%{fun: fun, args: args}) do
      args = @protocol.compile_body(args)
      fn(state, b) ->
        case args.(state, b) do
          {:ok, args, state} ->
            thunk = RemoteApplication.new(:erlang, fun, args, :shallow)
            {:ok, thunk, state}
          error ->
            error
        end
      end
    end
  end
end
