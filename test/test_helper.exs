defmodule EtudeTestHelper do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: false
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

    assertion_block = format_assertion_block(assertion)

    resolve = &__MODULE__.resolve/7

    opts = [file: __CALLER__.file,
            native: Mix.env == :bench]

    module = quote do
      defmodule unquote(mod) do
        use Etude
        alias Etude.Node.Assign
        alias Etude.Node.Block
        alias Etude.Node.Call
        alias Etude.Node.Case
        alias Etude.Node.Collection
        alias Etude.Node.Comprehension
        alias Etude.Node.Cond
        alias Etude.Node.Partial
        alias Etude.Node.Prop
        alias Etude.Node.Var

        defetude unquote(functions), unquote(opts)
      end
    end

    outV = Macro.var(:out, nil)
    resV = Macro.var(:res, nil)
    stateV = Macro.var(:state, nil)

    [{main, _}|_] = functions

    quote do
      unquote(module)
      if Mix.env == :bench do
        bench unquote(name) do
          unquote(mod).unquote(main)(unquote(state), unquote(resolve))
        end
      else
        test unquote(name) do
          ref = :erlang.make_ref()

          unquote(outV) = try do
            unquote(mod).unquote(main)(unquote(state), unquote(resolve), ref)
          catch
            {error, state2} ->
              {{:error, error}, state2}
          end

          case unquote(outV) do
            {unquote(resV) = {:error, _}, unquote(stateV)} ->
              unquote(assertion_block)
            {unquote(resV), unquote(stateV)} ->
              unquote(assertion_block)
              ## memoized test
              {unquote(resV), unquote(stateV)} = unquote(mod).unquote(main)(unquote(stateV), unquote(resolve), ref)
              unquote(assertion_block)
          end
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
  def resolve(:test, :partial, [fun, props], state, _, _, _) do
    {:partial, {fun, props}, state}
  end
  def resolve(:test, :partial, [module, fun, props], state, _, _, _) do
    {:partial, {module, fun, props}, state}
  end
  def resolve(:test, :partial_wo_state, [fun, props], _, _, _, _) do
    {:partial, {fun, props}}
  end
  def resolve(:test, :partial_wo_state, [module, fun, props], _, _, _, _) do
    {:partial, {module, fun, props}}
  end
  def resolve(:test, :async, [value], _, parent, ref, _) do
    {:ok, spawn(fn ->
      :timer.sleep(10)
      send(parent, {:ok, value, ref})
    end)}
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
  def resolve(:errors, :immediate, _, _, _, _, _) do
    {:error, :immediate}
  end
  def resolve(:errors, :async, _, _, parent, ref, _) do
    {:ok, spawn(fn ->
      :timer.sleep(10)
      send(parent, {:error, :async, ref})
    end)}
  end
  def resolve(_, _, _, _, _, _, _) do
    {:ok, nil}
  end
end

ExUnit.start()
if Mix.env == :bench do
  Benchfella.start(mem_stats: :include_sys)
end
