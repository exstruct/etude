defmodule EtudeTest.Assign do
  use EtudeTestHelper

  etudetest "should assign a variable", [
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

  etudetest "should use a nested variable", [
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