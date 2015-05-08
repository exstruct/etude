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

  etudetest "shouldn't matter in which order variables are assigned", [
    render: [
      %Assign{
        name: :first,
        expression: %Var{name: :second}
      },
      %Assign{
        name: :second,
        expression: "Foo"
      },
      %Var{name: :first}
    ]
  ], "Foo"

end