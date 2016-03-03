defmodule Test.Etude.Serializer do
  use Test.Etude.Case
  alias Etude.Serializer
  alias Serializer.TERM
  alias Serializer.JSON

  term = [
    {
      quote do
        thunk_value({
          thunk_value("Hello"),
          thunk_value("Robert")
        })
      end,
      {"Hello", "Robert"}
    }
  ]

  json = [
    {
      quote(do: %{}),
      %{}
    },
    {
      quote(do: %{"foo" => "bar"}),
      %{"foo" => "bar"}
    },
    {
      quote(do: %{:undefined => 1}),
      %{}
    },
    {
      quote(do: %{"foo" => :undefined}),
      %{}
    },
    {
      quote(do: :undefined),
      ""
    },
    {
      quote do
        %{
          "" => :empty,
          true => false,
          1 => 2
        }
      end,
      %{
        "" => "empty",
        "true" => false,
        "1" => 2
      }
    },
    {
      quote do
        [true,
         false,
         nil,
         :undefined,
         1,
         3.14,
         :hello,
         %{"name" => "Cameron"}]
      end,
      [true,
       false,
       nil,
       nil,
       1,
       3.14,
       "hello",
       %{"name" => "Cameron"}]
    },
    {
      quote do
        [1,[2,[3,[4,await_value(5),6]]]]
      end,
      [1,[2,[3,[4,5,6]]]]
    },
    {
      quote do
        %{"message" => thunk_value("Hello")}
      end,
      %{"message" => "Hello"}
    },
    {
      quote do
        %{"message" => thunk_value(%{
          "Hello" => thunk_value("Joe")
        })}
      end,
      %{"message" => %{"Hello" => "Joe"}}
    },
    {
      quote do
        await_value(%{
          "foo" => await_value(%{
            "bar" => await_value(%{
              "a" => "b",
              "baz" => await_value("bang"),
              "hello" => "world",
            })
          })
        })
      end,
      %{
        "foo" => %{
          "bar" => %{
            "a" => "b",
            "baz" => "bang",
            "hello" => "world"
          }
        }
      }
    }
  ]

  for {data, expected} <- term do
    test "term #{:erlang.phash2(data)}" do
      serialize(TERM, unquote(data), unquote(Macro.escape(expected)), &(&1))
    end
  end

  for {data, expected} <- json do
    test "json #{:erlang.phash2(data)}" do
      json(unquote(data), unquote(Macro.escape(expected)))
    end
  end

  def json(data, expected) do
    serialize(JSON, data, expected, fn
      ("") ->
        ""
      (json) ->
        try do
          Poison.decode!(json)
        rescue
          e in Poison.SyntaxError ->
            IO.puts json
            reraise e, System.stacktrace
        end
    end)
  end

  defp serialize(serializer, data, expected, decode) do
    state = %Etude.State{unhandled_warning: false}
    {actual, _} = serializer.serialize(data, state, [])
    actual = decode.(actual)

    assert actual == expected
  end

  defp thunk_value(value) do
    %Etude.Thunk.Continuation{function: fn(_, state) ->
      {value, state}
    end}
  end

  defp await_value(value) do
    %Etude.Thunk.Continuation{function: fn(_, state) ->
      {:await, %Etude.Thunk.Continuation{function: fn(_, state) ->
        {value, state}
      end}, Etude.Mailbox.send(state, :foo)}
    end}
  end
end
