defmodule EtudeTest.Block do
  use EtudeTestHelper

  etudetest "should shadow variables in a block", [
    render: [
      %Assign{
        name: :parent,
        expression: :parent
      },
      %Assign{
        name: :shadow,
        expression: :parent
      },
      %Block{
        children: [
          %Assign{
            name: :shadow,
            expression: :child
          },
          {
            %Var{name: :parent},
            %Var{name: :shadow}
          }
        ]
      }
    ]
  ], {:parent, :child}

  etudetest "should use vars outside of blocks", [
    render: [
      %Assign{
        expression: true, line: nil,
        name: :action
      },
      %Cond{
        arms: [
          %Block{
            children: [
              %Var{
                line: nil,
                name: :action
              }
            ],
            line: nil, side_effects: true
          },
        ],
        expression: %Var{
          line: nil,
          name: :action
        },
        line: nil
      }
    ]
  ], true
end