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
end