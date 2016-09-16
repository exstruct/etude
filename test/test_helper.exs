defmodule Test.Etude.Case do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: true
      import unquote(__MODULE__)
      import Fugue.Assertions

      setup do
        :rand.seed(:exs1024, {ExUnit.configuration()[:seed], 0, 0})
        :ok
      end
    end
  end
end

seed = ExUnit.configuration()[:seed] || :erlang.phash2(:crypto.rand_bytes(20))
ExUnit.start([seed: seed])
