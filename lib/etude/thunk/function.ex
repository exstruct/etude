defmodule Etude.Thunk.Function do
  defstruct function: nil
end

defimpl Etude.Thunk, for: Etude.Thunk.Function do
  def resolve(%{function: function}, state) when is_function(function) do
    {function, state}
  end

  # defp wrap_fun(state, _fun) do
  #   Process.put(:WRAPPED_FUN_STATE, state)
  #   # case erlang.fun_info(fun, :arity) do

  #   # end
  # end

  # defp unwrap_fun_res(res) do
  #   case Process.get(:WRAPPED_FUN_STATE) do
  #     {:await, state} ->
  #       {:await, res, state}
  #     state ->
  #       {res, state}
  #   end
  # end

  for arity <- 1..64 do
    args = 1..(arity - 1) |> Enum.map(&Macro.var(:"arg_#{&1}", nil))

    defp gen_fun(unquote(arity), fun) do
      fn(unquote_splicing(args)) ->
        case Process.get(:WRAPPED_FUN_STATE) do
          nil ->
            ## TODO support cross-process functions
            throw :fun_called_in_other_process
          state ->
            case fun.(state, unquote_splicing(args)) do
              {value, state} ->
                Process.put(:WRAPPED_FUN_STATE, state)
                value
              {:await, thunk, state} ->
                Process.put(:WRAPPED_FUN_STATE, {:await, state})
                thunk
            end
        end
      end
    end
  end
end
