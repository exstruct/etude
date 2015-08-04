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

end
