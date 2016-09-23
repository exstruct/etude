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
        %{
          bindings: %{foo: 2},
          value: %{[1,2] => :bar},
          body: :bar
        },
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

  for test <- tests do
    for assertion <- test.assertions do
      bindings = assertion[:bindings] || %{}

      test "#{test.name} - #{inspect(assertion.value)} (#{inspect(bindings)})" do
        m = Match.compile(
          unquote(Macro.escape(test.pattern)),
          unquote(Macro.escape(test[:guard])),
          unquote(Macro.escape(test[:body]))
        )

        value = Etude.Future.of(unquote(Macro.escape(assertion.value)))
        bindings = unquote(Macro.escape(bindings))

        body_check = unquote(
          case Map.fetch(assertion, :body) do
            :error ->
              quote location: :keep do
                fn(body) ->
                  assert {:error, _} = body
                end
              end
            {:ok, body} ->
              quote location: :keep do
                fn(body) ->
                  assert {:ok, unquote(Macro.escape(body))} = body
                end
              end
          end
        )

        m
        |> Etude.Match.Executable.execute(value, bindings)
        |> f()
        |> body_check.()
      end
    end
  end

  test "binary destruct" do
    p = Match.binary(fn("Hello, " <> name) ->
      %{name: name}
    end)

    m = Match.compile(p, nil, Match.binding(:name))

    m
    |> Etude.Match.Executable.execute("Hello, Joe", %{})
    |> f()
    |> assert_term_match({:ok, "Joe"})

    m
    |> Etude.Match.Executable.execute("Hello Robert", %{})
    |> f()
    |> assert_term_match({:error, _})
  end

  test "with bindings" do
    b = Match.with_bindings(fn(%{name: name}) ->
      name
      |> Etude.Future.to_term()
      |> Etude.Future.map(&("Hello, " <> &1))
    end)

    m = Match.compile(Match.binding(:name), nil, b)

    m
    |> Etude.Match.Executable.execute("Mike", %{})
    |> f()
    |> assert_term_match({:ok, "Hello, Mike"})
  end

  defp f(future) do
    future
    |> Etude.Traversable.traverse()
    |> Etude.fork()
  end
end
