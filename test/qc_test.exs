defmodule ExprTest.QC do
  use ExUnit.Case, async: false
  use ExCheck
  use Expr
  alias Expr.Node.Assign
  alias Expr.Node.Call
  alias Expr.Node.Collection
  alias Expr.Node.Comprehension
  alias Expr.Node.Cond
  alias Expr.Node.Partial
  alias Expr.Node.Var

  ## TODO lib this
  defmacro delay(x) do
    quote do
      fn ->
        unquote(x)
      end
    end
  end

  def smaller(domain) do
    sized fn(size) ->
      resize(:random.uniform((div(size, 2))+1), domain)
    end
  end

  def exq_struct(%{:__struct__ => name} = args) do
    args = Map.delete(args, :__struct__)
    domain(:struct, fn(self, size) ->
      args = Enum.reduce(args, [], fn({key, fun}, acc) ->
        {_, val} = pick(fun, size)
        [{key, val} | acc]
      end)
      {self, struct(name, args)}
    end, fn(self, val) ->
      {self, val}
    end)
  end
  ## END LIB

  def expr_literal do
    sized &expr_literal/1
  end

  def expr_literal(0) do
    oneof [
      int,
      atom,
      binary,
      bool,
      char
    ]
  end
  def expr_literal(k) do
    frequency [
      {40, expr_literal(0)},
      {3, list(smaller(delay(expr_literal)))},
      {2, tuple(smaller(delay(expr_literal)))}
    ]
  end

  def expr_call do
    exq_struct %Call{
      module: atom,
      function: atom,
      arguments: [bool(), int(0, 100) | list(smaller(delay(expr_expression)))],
      line: pos_integer
    }
  end

  def expr_cond do
    exq_struct %Cond{
      expression: delay(expr_expression),
      arms: delay(oneof [
        [],
        [expr_expression],
        [expr_expression, expr_expression]
      ]),
      line: pos_integer
    }
  end

  def expr_comprehension do
    exq_struct %Comprehension{
      expression: delay(list(expr_expression))
      ## TODO
    }
  end

  def expr_expression do
    frequency [
      {50, oneof [
        expr_literal
      ]},
      {10, oneof [
        expr_cond,
        expr_call
      ]}
    ]
  end

  def expr_render do
    expr_expression
  end

  @tag timeout: :infinity
  property :literal do
    for_all ast in expr_render do
      main = :render
      mod = create_module(ast, main)
      ref = :erlang.make_ref
      state = :STATE
      {time, {out1, state1}} = :timer.tc(mod, main, [state, &resolve/7, ref])
      # TODO report timings and metrics
      {out2, state2} = apply(mod, main, [state, &resolve/7, ref])
      state1 == state and state2 == state and
        out1 == out2
    end
  end

  def resolve(mod, fun, [true, time | args], _state, parent, ref, _attrs) do
    {:ok, spawn(fn ->
      :timer.sleep(time)
      send(parent, {:ok, {:SPAWN, mod, fun, args}, ref})
    end)}
  end
  def resolve(mod, fun, [_, _ | args], _state, _parent, _ref, _attrs) do
    {:ok, {:CALL, mod, fun, args}}
  end

  def create_module(x, main) do
    name = "ExprTest.QC.#{:erlang.phash2({x, :os.timestamp})}" |> String.to_atom
    mod = quote do
      defmodule unquote(name) do
        use Expr
        defexpr unquote(main), unquote([Macro.escape(x)])
        # unquote_splicing do
        #   for {name, ast} <- functions do
        #     quote do
        #       defexpr unquote(name), unquote(ast)
        #     end
        #   end
        # end
      end
    end
    Code.eval_quoted(mod, [], __ENV__)
    name
  end
end