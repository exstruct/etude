defmodule ExprTestHelper do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case
      use Benchfella
      import ExprTestHelper
    end
  end

  defmacro exprtest(name, functions, assertion, state \\ :STATE) do
    mod = name
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    mod = [hd(__CALLER__.context_modules) | mod]
    |> Enum.join(".")
    |> String.to_atom

    [{main, _}|_] = functions

    assertion_block = format_assertion_block(assertion)

    resolve = &__MODULE__.resolve/7

    quote do
      defmodule unquote(mod) do
        if System.get_env("NATIVE") do
          @compile :native
          @compile {:hipe, [:o3]}
        end
        use Expr
        alias Expr.Node.Assign
        alias Expr.Node.Call
        alias Expr.Node.Collection
        alias Expr.Node.Comprehension
        alias Expr.Node.Cond
        alias Expr.Node.Partial
        alias Expr.Node.Var

        unquote_splicing do
          for {name, ast} <- functions do
            quote do
              defexpr unquote(name), unquote(ast)
            end
          end
        end
      end
      test unquote(name) do
        ref = :erlang.make_ref()
        {unquote(Macro.var(:res, nil)), unquote(Macro.var(:state, nil))} = unquote(mod).unquote(main)(unquote(state), unquote(resolve), ref)
        unquote(assertion_block)
        ## memoized test
        {unquote(Macro.var(:res, nil)), unquote(Macro.var(:state, nil))} = unquote(mod).unquote(main)(unquote(state), unquote(resolve), ref)
        unquote(assertion_block)
      end
      if Mix.env == :bench do
        bench unquote(name) do
          unquote(mod).unquote(main)(unquote(state), unquote(resolve))
        end
      end
    end
  end

  def format_assertion_block([do: block]) do
    quote do
      assert unquote(Macro.var(:state, nil)) != nil
      unquote(block)
    end
  end
  def format_assertion_block(assertion) do
    quote do
      assert unquote(Macro.var(:res, nil)) == unquote(assertion)
      assert unquote(Macro.var(:state, nil)) != nil
    end
  end

  def resolve(:test, :passthrough_and_modify, [a], state, _, _, _) do
    {:ok, {a, state}, [1, state]}
  end
  def resolve(:bool, val, _, _, _, _, _) do
    {:ok, val}
  end
  def resolve(:math, :add, [a, b], _, _, _, _) do
    {:ok, a + b}
  end
  def resolve(:math, :zero, _, _, _, _, _) do
    {:ok, 0}
  end
  def resolve(_, _, _, _, _, _, _) do
    {:ok, nil}
  end
end

ExUnit.start()
if Mix.env == :bench do
  Benchfella.start(mem_stats: :include_sys)
end