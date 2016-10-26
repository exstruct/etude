etude [![Build Status](https://travis-ci.org/exstruct/etude.png?branch=master)](https://travis-ci.org/exstruct/etude) [![Hex.pm](https://img.shields.io/hexpm/v/etude.svg)](https://hex.pm/packages/etude)
====

futures for elixir/erlang

## Example

```elixir
1..50
|> Enum.map(fn(i) ->
  fn ->
    # some expensive operation
    i
  end
  |> Etude.async()
  |> Etude.retry(1) # retry once if it fails
end)
|> Etude.join(10) # concurrency of 10
|> Etude.map(&Enum.sum/1)
|> Etude.fork!()
```
