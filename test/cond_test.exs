defmodule EtudeTest.Cond do
  use EtudeTestHelper

  etudetest "should render a no-armed cond", [
    render: [
      %Cond{
        expression: %Call{
          module: :bool,
          function: true
        }
      }
    ]
  ], :undefined

  etudetest "should render a one-armed cond (truthy)", [
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

  etudetest "should render a one-armed cond (falsy)", [
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

  etudetest "should render a two-armed cond (truthy)", [
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

  etudetest "should render a two-armed cond (falsy)", [
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