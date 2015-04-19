defmodule ExprTest.Assign do
  use ExprTestHelper

  exprtest "should assign a variable", [
    render: [
      %Assign{
        name: :var,
        expression: "Robert"
      },
      %Var{
        name: :var
      }
    ]
  ], "Robert"

  exprtest "should use a nested variable", [
    render: [
      %Assign{
        name: :key,
        expression: "name"
      },
      %Assign{
        name: :value,
        expression: "Joe"
      },
      [%{%Var{name: :key} => %Var{name: :value}}]
    ]
  ], [%{"name" => "Joe"}]
end