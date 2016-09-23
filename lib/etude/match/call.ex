defmodule Etude.Match.Call do
  defstruct [:fun, :args]

  defimpl Etude.Matchable do
    alias Etude.Match.Executable

    def compile(call) do
      throw {:invalid_call, call}
    end

    @guard_0 ~w(
      node self
    )a

    @guard_1 ~w(
      is_atom is_float is_integer is_list is_number is_pid is_port is_reference is_tuple is_map is_binary is_function

      not abs hd length map_size round size tl tuple_size trunc
    )a

    @guard_2 ~w(
      and or xor andalso orelse

      element + - * div rem band bor bxor bnot bsl bsr > >= < =< =:= == =/= /=
    )a

    def compile_body(%{fun: fun, args: []}) when fun in @guard_0 do
      %Executable{
        module: __MODULE__,
        function: :__execute_0__,
        env: fun
      }
    end
    def compile_body(%{fun: fun, args: [arg]}) when fun in @guard_1 do
      arg = @protocol.compile_body(arg)
      %Executable{
        module: __MODULE__,
        function: :__execute_1__,
        env: {fun, arg}
      }
    end
    def compile_body(%{fun: fun, args: [arg1, arg2]}) when fun in @guard_2 do
      arg_1 = @protocol.compile_body(arg1)
      arg_2 = @protocol.compile_body(arg2)
      %Executable{
        module: __MODULE__,
        function: :__execute_2__,
        env: {fun, arg_1, arg_2}
      }
    end

    def __execute_0__(fun, _) do
      Etude.Future.of(apply(:erlang, fun, []))
    end

    def __execute_1__({fun, arg}, b) do
      args = arg |> Executable.execute(b) |> Etude.Future.to_term() |> Etude.Future.map(&[&1])
      Etude.Future.call(:erlang, fun, args)
    end

    def __execute_2__({fun, arg_1, arg_2}, b) do
      args = [
        arg_1 |> Executable.execute(b) |> Etude.Future.to_term(),
        arg_2 |> Executable.execute(b) |> Etude.Future.to_term()
      ] |> Etude.Future.parallel()

      Etude.Future.call(:erlang, fun, args)
    end
  end
end
