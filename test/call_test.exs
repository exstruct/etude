defmodule ExprTest.Call do
  use ExprTestHelper

  exprtest "should call a function with no arguments", [
    render: [
      %Call{
        module: :math,
        function: :zero,
      }
    ]
  ], 0

  exprtest "should call a function with static arguments", [
    render: [
      %Call{
        module: :math,
        function: :add,
        arguments: [
          1,
          1
        ]
      }
    ]
  ], 2

  exprtest "should memoize function calls", [
    render: [
      {%Call{
        module: :test,
        function: :passthrough_and_modify,
        arguments: [1]
      },
      %Call{
        module: :test,
        function: :passthrough_and_modify,
        arguments: [1]
      }}
    ]
  ], {{1,:STATE}, {1,:STATE}}

end