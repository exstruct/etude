defmodule Test.Etude.Match do
  use Test.Etude.Case
  alias Etude.Match

  tests = [
    %{
      name: "literal",
      pattern: 1,
      body: true,
      assertions: [
        %{
          value: 1,
          body: true
        },
        %{
          value: 2
        }
      ]
    },
    %{
      name: "binding match",
      pattern: Match.binding(:foo),
      body: Match.binding(:foo),
      assertions: [
        %{
          bindings: %{foo: :bar},
          value: :bar,
          body: :bar
        },
        %{
         bindings: %{foo: :baz},
         value: :bar,
        },
        %{
          value: :baz,
          body: :baz
        }
      ]
    },
    %{
      name: "tuple match",
      pattern: {Match.binding(:foo), Match.binding(:foo)},
      body: Match.binding(:foo),
      assertions: [
        %{
          bindings: %{foo: :bar},
          value: {:bar, :bar},
          body: :bar
        },
        %{
          bindings: %{foo: :baz},
          value: {:bar, :bar}
        },
        %{
          value: {:baz, :baz},
          body: :baz
        },
        %{
          value: {:bar, :baz}
        }
      ]
    },
    %{
      name: "list match",
      pattern: [Match.binding(:foo), Match.binding(:bar)],
      body: {Match.binding(:foo), Match.binding(:bar)},
      assertions: [
        %{
          value: [1, 2],
          body: {1, 2}
        }
      ]
    },
    %{
      name: "cons",
      pattern: [Match.binding(:foo) | Match.binding(:bar)],
      body: Match.binding(:bar),
      assertions: [
        %{
          value: [1],
          body: []
        },
        %{
         value: [1, 2],
         body: [2]
        },
        %{
          value: [1 | 2],
          body: 2
        }
      ]
    },
    %{
      name: "map",
      pattern: %{
        foo: Match.binding(:foo)
      },
      body: Match.binding(:foo),
      assertions: [
        %{
          value: %{foo: :bar},
          body: :bar
        },
        %{
          value: %{baz: :bar}
        },
        %{
          bindings: %{foo: 1},
          value: %{foo: 1},
          body: 1
        },
        %{
          bindings: %{foo: 1},
          value: %{foo: 2}
        }
      ]
    },
    %{
      name: "map list key",
      pattern: %{
        [1, Match.binding(:foo)] => Match.binding(:bar)
      },
      body: Match.binding(:bar),
      assertions: [
        # %{
        #   bindings: %{foo: 2},
        #   value: %{[1,2] => :bar},
        #   body: :bar
        # },
        %{
          value: %{[1,3] => :baz},
          body: :baz
        },
        %{
          value: %{[1] => :baz}
        }
      ]
    },
    %{
      name: "nested body",
      pattern: nil,
      body: %{
        Match.binding(:foo) => {1, [Match.binding(:bar)]}
      },
      assertions: [
        %{
          bindings: %{foo: :foo, bar: :bar},
          value: nil,
          body: %{foo: {1, [:bar]}}
        }
      ]
    },
    %{
      name: "guards",
      pattern: Match.binding(:foo),
      guard: Match.call(:is_atom, [Match.binding(:foo)]),
      body: true,
      assertions: [
        %{
          value: :atom,
          body: true
        },
        %{
          value: 1
        }
      ]
    }
  ]

  defmacrop assert_body(:error) do
    quote do
      :error
    end
  end
  defmacrop assert_body({:ok, body}) do
    quote do
      unquote(Macro.escape(body))
    end
  end

  for test <- tests do
    for assertion <- test.assertions do
      bindings = assertion[:bindings] || %{}

      test "#{test.name} - #{inspect(assertion.value)} (#{inspect(bindings)})" do
        m = Match.compile(
          unquote(Macro.escape(test.pattern)),
          unquote(Macro.escape(test[:guard])),
          unquote(Macro.escape(test[:body]))
        )

        assert = fn(body, _state) ->
          assert assert_body(unquote(Map.fetch(assertion, :body))) = body
          :ok
        end

        test = fn(bindings, value) ->
          v = Match.exec(m, value, %Etude.State{}, bindings)

          case v do
            {:error, state} ->
              assert.(:error, state)
            {:ok, value, state} ->
              resolve(value, state, assert)
            {:await, thunk, state} ->
              resolve(thunk, state, assert)
          end
        end

        for _ <- 0..1000 do
          :ok = test.(
            thunkify_b(unquote(Macro.escape(bindings))),
            thunkify(unquote(Macro.escape(assertion.value)))
          )
        end
      end
    end
  end

  defp resolve(thunk, state, fun) do
    case Etude.resolve(thunk, state) do
      {:ok, value, state} ->
        fun.(value, state)
      {:error, state} ->
        fun.(:error, state)
    end
  end

  defp thunkify(v) do
    if :rand.uniform() > 0.5 do
      thunkify_t(v)
    else
      v
    end
  end

  defp thunkify_b(map) do
    map
    |> Enum.map(fn({k, v}) -> {k, thunkify(v)} end)
    |> :maps.from_list()
  end

  defp thunkify_t(map) when is_map(map) do
    map
    |> Enum.map(fn({k, v}) -> {k, thunkify(v)} end)
    |> :maps.from_list()
    |> maybe_thunkify()
  end
  defp thunkify_t(t) when is_tuple(t) do
    t
    |> :erlang.tuple_to_list()
    |> Enum.map(&thunkify/1)
    |> :erlang.list_to_tuple()
    |> maybe_thunkify()
  end
  defp thunkify_t([head | tail]) do
    [thunkify(head) | thunkify(tail)]
    |> maybe_thunkify()
  end
  defp thunkify_t(value) do
    maybe_thunkify(value)
  end

  defp maybe_thunkify(value) do
    if :rand.uniform > 0.5 do
      await(maybe_thunkify(value))
    else
      thunk(value)
    end
  end

  defp await(value) do
    cont([value], fn([value], s) ->
      {:await, value, s}
    end)
  end

  defp thunk(value) do
    cont([value], fn([value], s) ->
      {:ok, value, s}
    end)
  end

  defp cont(arguments, fun) do
    %Etude.Thunk.Continuation{function: fun, arguments: arguments}
  end
end
