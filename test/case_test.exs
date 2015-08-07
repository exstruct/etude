defmodule EtudeTest.Case do
  use EtudeTestHelper

  etudetest "should support case statements", [
    render: [
      %Case{
        expression: 3,
        clauses: [
          {%Assign{name: :foo}, nil, %Var{name: :foo}}
        ]
      }
    ]
  ], 3

  etudetest "should support assign variables correctly", [
    render: [
      %Case{
        expression: {1, 1},
        clauses: [
          {{%Assign{name: :a}, %Assign{name: :b}}, nil, %Call{module: :erlang,
                                                              attrs: %{native: true},
                                                              function: :+,
                                                              arguments: [%Var{name: :a}, %Var{name: :b}]}}
        ]
      }
    ]
  ], 2

  etudetest "should support pattern matching in case statements", [
    render: [
      %Case{
        expression: {[%{foo: [{1}]}]},
        clauses: [
          {{[%{foo: [{%Assign{name: :foo}}]}]}, nil, %Var{name: :foo}}
        ]
      }
    ]
  ], 1

  etudetest "should support cons matching in case statements", [
    render: [
      %Case{
        expression: [1,{2,2.5,2.7},3,4,5],
        clauses: [
          {%Cons{children: [1,{2,2.5,2.7},3], expression: %Assign{name: :foo}}, nil, %Var{name: :foo}}
        ]
      }
    ]
  ], [4,5]

  etudetest "should support wildcard matches", [
    render: [
      %Case{
        expression: [1,2,3],
        clauses: [
          {[1,2,%Var.Wildcard{}], nil, "wildcard"}
        ]
      }
    ]
  ], "wildcard"

end
