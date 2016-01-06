# there's gotta be a better way
Application.ensure_all_started(:excheck)
Code.eval_file("./test/qc_test_helper.exs")

defmodule EtudeTest.QC do
  use ExUnit.Case, async: false
  use ExCheck
  use Etude
  alias Etude.Node.Assign
  alias Etude.Node.Call
  alias Etude.Node.Comprehension
  alias Etude.Node.Cond
  alias Etude.Node.Partial
  alias Etude.Node.Var

  ## TODO lib this
  defmacro delay(x) do
    quote do
      fn ->
        unquote(x)
      end
    end
  end

  def smaller(domain, factor \\ 2) do
    sized fn(size) ->
      resize(:random.uniform((div(size, factor))+1), domain)
    end
  end

  def larger(domain, factor \\ 2) do
    sized fn(size) ->
      resize(:random.uniform(size * factor), domain)
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

  def etude_literal do
    sized &etude_literal/1
  end

  def etude_literal(0) do
    oneof [
      int,
      atom,
      binary,
      bool,
      char
    ]
  end
  def etude_literal(k) do
    frequency [
      {40, etude_literal(0)},
      {3, list(smaller(delay(etude_expression)))},
      {3, map(smaller(delay(etude_expression), 8),
              smaller(delay(etude_expression)))},
      {2, tuple(smaller(delay(etude_expression)))}
    ]
  end

  def etude_assign(expression \\ delay(etude_expression)) do
    exq_struct %Assign{
      name: etude_varname,
      expression: expression,
      line: 1
    }
  end

  def etude_call do
    exq_struct %Call{
      module: atom,
      function: atom,
      arguments: [bool(), int(0, 100) | smaller(list(delay(etude_expression)), 4)],
      line: 1
    }
  end

  def etude_cond do
    exq_struct %Cond{
      expression: smaller(delay(etude_expression)),
      arms: delay(oneof [
        [],
        [smaller(etude_expression)],
        [nil, smaller(etude_expression)],
        [smaller(etude_expression), smaller(etude_expression)]
      ]),
      line: 1
    }
  end

  def etude_comprehension do
    comp = exq_struct %Comprehension{
      collection: smaller(delay(list(etude_expression))),
      key: oneof([etude_assign(nil), nil]),
      value: oneof([etude_assign(nil), nil]),
      expression: smaller(delay(etude_expression)),
      line: 1
    }
    bind comp, fn(info) ->
      if info.key, do:
        EtudeTest.QC.Helper.delete_var(info.key.name)
      if info.value, do:
        EtudeTest.QC.Helper.delete_var(info.value.name)
      info
    end
  end

  def etude_expression do
    frequency [
      {30, etude_literal},
      {15, etude_cond},
      {20, etude_call},
      {5, smaller(etude_comprehension, 3)},
      {2, etude_var}
    ]
  end

  def etude_oplist do
    domain(:etude_oplist, fn(self, size) ->
      EtudeTest.QC.Helper.reset
      {_, vars} = pick(etude_varlist, size)
      {_, main} = pick(smaller(etude_expression), size)
      {self, vars ++ [main]}
    end, fn(self, val) ->
      ## TODO
      {self, val}
    end)
  end

  def etude_var do
    domain(:etude_var, fn(self, size) ->
      case EtudeTest.QC.Helper.get_vars do
        [] ->
          {_, var} = pick(etude_literal(0), size)
          {self, var}
        vars ->
          {_, var} = pick(etude_varstruct(oneof(vars)), size)
          {self, var}
      end
    end, fn(self, val) ->
      ## TODO
      {self, val}
    end)
  end

  def etude_varlist do
    smaller(list(frequency([
      {10, smaller(etude_assign)},
      {2, smaller(etude_call)}
    ])))
  end

  def etude_varname do
    var = suchthat(larger(atom, 8), fn(val) ->
      !EtudeTest.QC.Helper.exists_var(val)
    end)

    bind var, fn(val) ->
      EtudeTest.QC.Helper.put_var(val)
      val
    end
  end

  def etude_varstruct(name) do
    exq_struct %Var{
      name: name,
      line: 1
    }
  end

  if Mix.env == :test do
    @tag timeout: :infinity
    property :etude do
      EtudeTest.QC.Helper.start_link
      for_all ast in etude_oplist do
        main = :render
        IO.puts "================================================================"
        IO.puts "===== compile:begin"
        mod = create_module(ast, main)
        IO.puts "===== compile:end #{mod}"
        ref = :erlang.make_ref
        state = :STATE
        IO.puts "===== render:begin"
        {time, {out1, state1}} = :timer.tc(mod, main, [state, &resolve/7, ref])
        IO.puts "===== render:end #{format_microseconds(time)}"

        IO.puts "===== render:cache:begin"
        {cachetime, {out2, state2}} = :timer.tc(mod, main, [state, &resolve/7, ref])
        IO.puts "===== render:cache:end #{format_microseconds(cachetime)}"
        state1 == state and state2 == state and
          out1 == out2
      end
    end
  end

  defp format_microseconds(time) do
    "#{(time / 1000)}ms"
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
    name = "EtudeTest.QC.#{:erlang.phash2({x, :os.timestamp})}" |> String.to_atom
    mod = quote do
      defmodule unquote(name) do
        use Etude
        defetude unquote([{main, Macro.escape(x)}])
        # unquote_splicing do
        #   for {name, ast} <- functions do
        #     quote do
        #       defetude unquote(name), unquote(ast)
        #     end
        #   end
        # end
      end
    end
    Code.eval_quoted(mod, [], __ENV__)
    name
  end
end