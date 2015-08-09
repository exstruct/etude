defmodule Etude.Dict.Test do
  use ExUnit.Case

  alias Etude.Dict

  test "Map.cache_key/1" do
    assert Dict.cache_key(%{foo: :bar})
  end

  test "Map.delete/3" do
    initial = %{foo: :bar}
    assert {:ok, %{}, ^initial} = Dict.delete(initial, :foo, dummy_op)
  end

  # test "Map.drop/3" do
  #   initial = %{foo: :bar, baz: :bang}
  #   assert {:ok, %{}, ^initial} = Dict.drop(initial, [:foo, :baz], dummy_op)
  # end

  test "Map.fetch/3" do
    initial = %{foo: 1}
    assert {:ok, _, ^initial} = Dict.fetch(initial, :foo, dummy_op)
  end

  test "Map.load/2" do
    initial = %{foo: :bar}
    assert {:ok, ^initial} = Dict.load(initial, dummy_op)
  end

  test "Map.put/4" do
    initial = %{}
    assert {:ok, %{foo: :bar}, ^initial} = Dict.put(initial, :foo, :bar, dummy_op)
  end

  test "Map.to_list/2" do
    initial = %{foo: :bar}
    assert {:ok, [foo: :bar], ^initial} = Dict.to_list(initial, dummy_op)
  end

  defp dummy_op do
    :DUMMY
  end
end
