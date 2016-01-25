defmodule Test.Etude do
  use Test.Etude.Case

  for value <- [1, 1.0, "foo", :bar, {}, %{}, []] do
    test "resolves #{inspect(value)}" do
      assert unquote(Macro.escape(value)) == Etude.resolve(unquote(Macro.escape(value)))
    end
  end
end
