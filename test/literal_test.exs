defmodule ExprTest.Literal do
  use ExUnit.Case
  use ExprTestHelper

  exprtest "should render nil without expressions", [
    render: []
  ], nil

  exprtest "should render an integer", [
    render: [1]
  ], 1

  exprtest "should render a float", [
    render: [3.14]
  ], 3.14

  exprtest "should render an atom", [
    render: [:foo]
  ], :foo

  exprtest "should render a binary", [
    render: ["IT WORKS"]
  ], "IT WORKS"

  exprtest "should render a list", [
    render: [
      ["Mike", "Joe", "Robert"]
    ]
  ], ["Mike", "Joe", "Robert"]

  exprtest "should render a tuple", [
    render: [
      {"Mike", "Joe", "Robert"}
    ]
  ], {"Mike", "Joe", "Robert"}

  exprtest "should render a map", [
    render: [
      %{
        "name" => "Joe",
        "phone" => "555-555-5555"
      }
    ]
  ], %{
    "name" => "Joe",
    "phone" => "555-555-5555"
  }

  exprtest "should render a nested structure", [
    render: [
      {[%{"key" => [:foo, :bar, :baz]}]}
    ]
  ], {[%{"key" => [:foo, :bar, :baz]}]}
end