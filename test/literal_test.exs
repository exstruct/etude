defmodule EtudeTest.Literal do
  use EtudeTestHelper

  etudetest "should render nil without an expression", [
    render: []
  ], nil

  etudetest "should render an integer", [
    render: [1]
  ], 1

  etudetest "should render a float", [
    render: [3.14]
  ], 3.14

  etudetest "should render an atom", [
    render: [:foo]
  ], :foo

  etudetest "should render a binary", [
    render: ["IT WORKS"]
  ], "IT WORKS"

  etudetest "should render a list", [
    render: [
      ["Mike", "Joe", "Robert"]
    ]
  ], ["Mike", "Joe", "Robert"]

  etudetest "should render a tuple", [
    render: [
      {"Mike", "Joe", "Robert"}
    ]
  ], {"Mike", "Joe", "Robert"}

  etudetest "should render a map", [
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

  etudetest "should render a nested structure", [
    render: [
      {[%{"key" => [:foo, :bar, :baz]}]}
    ]
  ], {[%{"key" => [:foo, :bar, :baz]}]}
end