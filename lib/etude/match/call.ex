defmodule Etude.Match.Call do
  defstruct [:fun, :args]

  defimpl Etude.Matchable do
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
      fn(_) ->
        Etude.Future.of(apply(:erlang, fun, []))
      end
    end
    def compile_body(%{fun: fun, args: [arg]}) when fun in @guard_1 do
      arg_fun = @protocol.compile_body(arg)
      fn(b) ->
        args = arg_fun.(b) |> Etude.Future.to_term() |> Etude.Future.map(&[&1])
        Etude.Future.call(:erlang, fun, args)
      end
    end
    def compile_body(%{fun: fun, args: [arg1, arg2]}) when fun in @guard_2 do
      arg_1 = @protocol.compile_body(arg1)
      arg_2 = @protocol.compile_body(arg2)
      fn(b) ->
        args = [
          b |> arg_1.() |> Etude.Future.to_term(),
          b |> arg_2.() |> Etude.Future.to_term()
        ] |> Etude.Future.parallel()

        Etude.Future.call(:erlang, fun, args)
      end
    end
  end
end
