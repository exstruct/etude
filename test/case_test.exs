defmodule EtudeTest.Case do
  use EtudeTestHelper

  etudetest "should support case statements", [
    render: [
      %Case{
        expression: 3,
        clauses: [
          {[], %Assign{name: :foo}, %Var{name: :foo}}
        ]
      }
    ]
  ], :TODO
end
