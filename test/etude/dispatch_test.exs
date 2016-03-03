defmodule Test.Etude.Dispatch do
  use Test.Etude.Case
  alias Etude.Dispatch
  alias Dispatch.Fallback
  alias Etude.Thunk
  alias Thunk.Application

  test "dispatch fallback" do
    call = Fallback.resolve(:erlang, :+, 2)

    assert 3 == Etude.resolve(%{call | arguments: [1, 2]})
  end

  defmodule RewriteDispatch do
    use Dispatch

    rewrite :foo, :erlang
    rewrite :math.divide/2, :erlang.div/2
  end

  defmodule EtudeModule do
    def __etude__(:hello, 1, dispatch) do
      join = dispatch.resolve(Enum, :join, 1)
      %Application{
        function: fn(name) ->
          %{join | arguments: [["Hello, ", name]]}
        end,
        arity: 1
      }
    end
  end

  test "module rewrite" do
    call = __MODULE__.RewriteDispatch.resolve(:foo, :+, 2)
    assert 3 == Etude.resolve(%{call | arguments: [1, 2]})
  end

  test "function rewrite" do
    call = __MODULE__.RewriteDispatch.resolve(:math, :divide, 2)
    assert 2 == Etude.resolve(%{call | arguments: [4, 2]})
  end

  test "__etude__ call" do
    call = Fallback.resolve(__MODULE__.EtudeModule, :hello, 1)
    assert "Hello, Joe" == Etude.resolve(%{call | arguments: ["Joe"]})
  end
end
