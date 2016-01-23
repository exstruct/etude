defmodule Etude.Test.Case do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: true
      import unquote(__MODULE__)
    end
  end
end

seed = ExUnit.configuration()[:seed] || :erlang.phash2(:crypto.rand_bytes(20))
ExUnit.start([seed: seed])
