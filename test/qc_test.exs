## there's gotta be a better way
Code.eval_file("./test/qc_test_helper.exs")

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

  def smaller(domain, factor \\ 4) do
    sized fn(size) ->
      resize(:random.uniform((div(size, factor))+1), domain)
    end
  end

  def map(key_domain, value_domain) do
    bind list({key_domain, value_domain}), fn(list) ->
      :maps.from_list(list)
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
      ## TODO
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
      {3, list(smaller(delay(expr_expression)))},
      {3, map(smaller(delay(expr_expression)),
              smaller(delay(expr_expression)))},
      {2, tuple(smaller(delay(expr_expression)))}
    ]
  end

  def expr_assign do
    assign = exq_struct %Assign{
      name: atom,
      expression: delay(expr_expression),
      line: pos_integer
    }
    bind assign, fn(var) ->
      ExprTest.QC.Helper.put_var(var.name)
      var
    end
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
      expression: smaller(delay(expr_expression)),
      arms: delay(oneof [
        [],
        [smaller(expr_expression)],
        [smaller(expr_expression), smaller(expr_expression)]
      ]),
      line: pos_integer
    }
  end

  ## TODO
  def expr_comprehension do
    exq_struct %Comprehension{
      expression: delay(list(expr_expression))
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
      ]},
      {2, oneof [
        expr_var
      ]}
    ]
  end

  def expr_oplist do
    domain(:expr_oplist, fn(self, size) ->
      ExprTest.QC.Helper.reset
      {_, vars} = pick(expr_varlist, size)
      {_, main} = pick(expr_expression, size)
      {self, vars ++ [main]}
    end, fn(self, val) ->
      ## TODO
      {self, val}
    end)
  end

  def expr_var do
    domain(:expr_varname, fn(self, size) ->
      case ExprTest.QC.Helper.get_vars do
        [] ->
          {_, var} = pick(expr_literal, size)
          {self, var}
        vars ->
          {_, var} = pick(expr_varstruct(oneof(vars)), size)
          {self, var}
      end
    end, fn(self, val) ->
      ## TODO
      {self, val}
    end)
  end

  def expr_varlist do
    smaller(list(smaller(expr_assign, 10)))
  end

  def expr_varstruct(name) do
    exq_struct %Var{
      name: name,
      line: pos_integer
    }
  end

  if Mix.env == :test do
    @tag timeout: :infinity
    property :expr do
      ExprTest.QC.Helper.start_link
      for_all ast in expr_oplist do
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