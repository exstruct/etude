"test/fixtures/**/*.ex"
|> Path.wildcard()
|> Enum.map(&Code.require_file/1)

defmodule EtudeTestHelper.Random do
  def start_link(seed) do
    Agent.start_link(fn ->
      :random.seed({0, 0, seed})
      seed
    end, name: __MODULE__)
  end

  def uniform(num) do
    Agent.get(__MODULE__, fn _ ->
      :random.seed(:random.seed())
      :random.uniform(num)
    end)
  end

  def sleep(min, max) do
    amount = uniform(max - min) + min
    :timer.sleep(amount)
  end
end

defmodule EtudeTestHelper do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: false
      use Benchfella
      import EtudeTestHelper
      alias Etude.Node.Assign
      alias Etude.Node.Binary
      alias Etude.Node.Block
      alias Etude.Node.Call
      alias Etude.Node.Case
      alias Etude.Node.Collection
      alias Etude.Node.Comprehension
      alias Etude.Node.Cons
      alias Etude.Node.Cond
      alias Etude.Node.Dict
      alias Etude.Node.Partial
      alias Etude.Node.Prop
      alias Etude.Node.Try
      alias Etude.Node.Var
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
            native: Mix.env == :bench,
            timeout: 1000]

    module = quote do
      defmodule unquote(mod) do
        use Etude
        alias Etude.Node.Assign
        alias Etude.Node.Binary
        alias Etude.Node.Block
        alias Etude.Node.Call
        alias Etude.Node.Case
        alias Etude.Node.Collection
        alias Etude.Node.Comprehension
        alias Etude.Node.Cons
        alias Etude.Node.Cond
        alias Etude.Node.Dict
        alias Etude.Node.Partial
        alias Etude.Node.Prop
        alias Etude.Node.Try
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
          rescue
            e in Etude.Exception ->
              {{:error, e.error}, e.state}
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

  defmacro parse(ast) do
    quote bind_quoted: [
      ast: Macro.escape(ast, unquote: true)
    ] do
      ast
      |> Macro.postwalk(fn
        node = {name, meta, args} ->
          {name, meta |> Keyword.delete(:line), args}
        node ->
          node
      end)
      |> Etude.Compiler.elixir_to_etude(nil)
    end
  end

  def format_assertion_block([do: block]) do
    quote do
      assert nil != unquote(Macro.var(:state, nil))
      unquote(block)
    end
  end
  def format_assertion_block(assertion) do
    quote do
      assert unquote(assertion) == unquote(Macro.var(:res, nil))
      assert nil != unquote(Macro.var(:state, nil))
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
  def resolve(:test, :identity, [value], _, _, _, _) do
    {:ok, value}
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
      EtudeTestHelper.Random.sleep(10, 50)
      send(parent, {:error, :async, ref})
    end)}
  end
  def resolve(:lazy, :user, [id], _, _, _, _) do
    {:ok, %Etude.Fixtures.User{id: id}}
  end
  def resolve(_, _, _, _, _, _, _) do
    {:ok, nil}
  end
end

seed = ExUnit.configuration()[:seed] || :erlang.phash2(:crypto.rand_bytes(20))
EtudeTestHelper.Random.start_link(seed)
ExUnit.start([seed: seed])

if Mix.env == :bench do
  Benchfella.start(mem_stats: :include_sys)
end
