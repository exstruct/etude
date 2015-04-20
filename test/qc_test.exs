## there's gotta be a better way
Code.eval_file("./test/qc_test_helper.exs")

defmodule EtudeTest.QC do
  use ExUnit.Case, async: false
  use ExCheck
  use Etude
  alias Etude.Node.Assign
  alias Etude.Node.Call
  alias Etude.Node.Collection
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

  def smaller(domain, factor \\ 8) do
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
      {3, map(smaller(delay(etude_expression), 12),
              smaller(delay(etude_expression)))},
      {2, tuple(smaller(delay(etude_expression)))}
    ]
  end

  def etude_assign do
    assign = exq_struct %Assign{
      name: atom,
      expression: delay(etude_expression),
      line: pos_integer
    }
    bind assign, fn(var) ->
      EtudeTest.QC.Helper.put_var(var.name)
      var
    end
  end

  def etude_call do
    exq_struct %Call{
      module: atom,
      function: atom,
      arguments: [bool(), int(0, 100) | smaller(list(delay(etude_expression)))],
      line: pos_integer
    }
  end

  def etude_cond do
    exq_struct %Cond{
      expression: smaller(delay(etude_expression)),
      arms: delay(oneof [
        [],
        [smaller(etude_expression)],
        [smaller(etude_expression), smaller(etude_expression)]
      ]),
      line: pos_integer
    }
  end

  ## TODO
  def etude_comprehension do
    exq_struct %Comprehension{
      expression: delay(list(etude_expression))
    }
  end

  def etude_expression do
    frequency [
      {50, oneof [
        etude_literal
      ]},
      {10, oneof [
        etude_cond,
        etude_call
      ]},
      {2, oneof [
        etude_var
      ]}
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
    domain(:etude_varname, fn(self, size) ->
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
    smaller(list(smaller(etude_assign)))
  end

  def etude_varstruct(name) do
    exq_struct %Var{
      name: name,
      line: pos_integer
    }
  end

  if Mix.env == :test do
    @tag timeout: :infinity
    property :etude do
      EtudeTest.QC.Helper.start_link
      for_all ast in etude_oplist do
        main = :render
        IO.puts "\n\n==========================="
        IO.puts "===== compile:begin"
        mod = create_module(ast, main)
        IO.puts "===== compile:end #{mod}"
        ref = :erlang.make_ref
        state = :STATE
        IO.puts "===== render:begin"
        {time, {out1, state1}} = :timer.tc(mod, main, [state, &resolve/7, ref])
        IO.puts "===== render:end #{time}"
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
    name = "EtudeTest.QC.#{:erlang.phash2({x, :os.timestamp})}" |> String.to_atom
    mod = quote do
      defmodule unquote(name) do
        use Etude
        defetude unquote(main), unquote([Macro.escape(x)])
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