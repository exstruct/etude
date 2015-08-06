defmodule EtudeTest.Try do
  use EtudeTestHelper

  etudetest "should catch immediate errors", [
    render: [
      %Try{
        expression: %Call{module: :errors, function: :immediate, arguments: []},
        clauses: [
          {:error, %Assign{name: :err}, nil, %Var{name: :err}}
        ]
      }
    ]
  ], :immediate

  etudetest "should catch async errors", [
    render: [
      %Try{
        expression: %Call{module: :errors, function: :async, arguments: []},
        clauses: [
          {:error, %Assign{name: :err}, nil, %Var{name: :err}}
        ]
      }
    ]
  ], :async

end
