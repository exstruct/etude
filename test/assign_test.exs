defmodule EtudeTest.Assign do
  use EtudeTestHelper

  etudetest "should assign a variable", [
    render: [
      %Assign{
        name: :var,
        expression: "Robert",
        line: 1
      },
      %Var{
        name: :var,
        line: 2
      }
    ]
  ], "Robert"

  etudetest "should use a nested variable", [
    render: [
      %Assign{
        name: :key,
        expression: "name",
        line: 1
      },
      %Assign{
        name: :value,
        expression: "Joe",
        line: 2
      },
      [%{%Var{name: :key, line: 3} => %Var{name: :value, line: 3}}]
    ]
  ], [%{"name" => "Joe"}]

  etudetest "shouldn't matter in which order variables are assigned", [
    render: [
      %Assign{
        name: :first,
        expression: %Var{name: :second},
        line: 1
      },
      %Assign{
        name: :second,
        expression: "Foo",
        line: 2
      },
      %Var{name: :first, line: 3}
    ]
  ], "Foo"

end