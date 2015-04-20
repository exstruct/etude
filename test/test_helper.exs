defmodule EtudeTestHelper do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case
      use Benchfella
      import EtudeTestHelper
    end
  end

  defmacro etudetest(name, functions, assertion, state \\ :STATE) do
    mod = name
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    mod = ["EtudeTest#{:erlang.phash2(__CALLER__)}" | mod]
    |> Enum.join(".")
    |> String.to_atom

    [{main, _}|_] = functions

    assertion_block = format_assertion_block(assertion)

    resolve = &__MODULE__.resolve/7

    module = quote do
      defmodule unquote(mod) do
        use Etude
        alias Etude.Node.Assign
        alias Etude.Node.Call
        alias Etude.Node.Collection
        alias Etude.Node.Comprehension
        alias Etude.Node.Cond
        alias Etude.Node.Partial
        alias Etude.Node.Var

        unquote_splicing do
          for {name, ast} <- functions do
            quote do
              defetude unquote(name), unquote(ast)
            end
          end
        end
      end
    end

    quote do
      unquote(module)
      if Mix.env == :bench do
        bench unquote(name) do
          unquote(mod).unquote(main)(unquote(state), unquote(resolve))
        end
      else
        test unquote(name) do
          ref = :erlang.make_ref()
          {unquote(Macro.var(:res, nil)), unquote(Macro.var(:state, nil))} = unquote(mod).unquote(main)(unquote(state), unquote(resolve), ref)
          unquote(assertion_block)
          ## memoized test
          {unquote(Macro.var(:res, nil)), unquote(Macro.var(:state, nil))} = unquote(mod).unquote(main)(unquote(state), unquote(resolve), ref)
          unquote(assertion_block)
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