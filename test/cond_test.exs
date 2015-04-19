defmodule ExprTest.Cond do
  use ExprTestHelper

  exprtest "should render a no-armed cond", [
    render: [
      %Cond{
        expression: %Call{
          module: :bool,
          function: true
        }
      }
    ]
  ], :undefined

  exprtest "should render a one-armed cond (truthy)", [
    render: [
      %Cond{
        expression: %Call{
          module: :bool,
          function: true
        },
        arms: [
          :foo
        ]
      }
    ]
  ], :foo

  exprtest "should render a one-armed cond (falsy)", [
    render: [
      %Cond{
        expression: %Call{
          module: :bool,
          function: false
        },
        arms: [
          :foo
        ]
      }
    ]
  ], :undefined

  exprtest "should render a two-armed cond (truthy)", [
    render: [
      %Cond{
        expression: %Call{
          module: :bool,
          function: true
        },
        arms: [
          :foo,
          :bar
        ]
      }
    ]
  ], :foo

  exprtest "should render a two-armed cond (falsy)", [
    render: [
      %Cond{
        expression: %Call{
          module: :bool,
          function: false
        },
        arms: [
          :foo,
          :bar
        ]
      }
    ]
  ], :bar

end