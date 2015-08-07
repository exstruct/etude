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

  etudetest "should assign the variables correctly", [
    render: [
      %Try{
        expression: %Call{module: :errors, function: :immediate, arguments: []},
        clauses: [
          {:error, %Assign{name: :err}, nil, %Call{module: String.Chars,
                                                   function: :to_string,
                                                   arguments: [%Var{name: :err}],
                                                   attrs: %{native: true}}}
        ]
      }
    ]
  ], "immediate"

end
