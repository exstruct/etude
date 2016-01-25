defmodule Test.Etude.Cache do
  use Test.Etude.Case
  alias Etude.Cache

  data = ["foo", :bar, %{foo: :bar}, [1,[2,[3,[4,[5]]]]]]

  for {name, cache} <- [{"pid", quote(do: self())},
                        {"map", quote(do: %{})}] do
    for key <- data, value <- data do
      test "#{name} caches #{inspect(value)} with key #{inspect(key)}" do
        key = unquote(Macro.escape(key))
        value = unquote(Macro.escape(value))

        cache = unquote(cache)
        assert nil == Cache.get(cache, key)

        cache = Cache.put(cache, key, value)
        assert value == Cache.get(cache, key)

        cache = Cache.delete(cache, key)
        assert nil == Cache.get(cache, key)

        cache = Cache.put(cache, key, value)
        assert value == Cache.get(cache, key)

        cache = Cache.clear(cache)
        assert nil == Cache.get(cache, key)
      end
    end
  end
end
