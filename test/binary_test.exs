defmodule EtudeTest.Binary do
  use EtudeTestHelper

  etudetest "should construct a binary", [
    render: [
      %Binary{
        segments: [
          %Binary.Segment{
            expression: 255
          },
          %Binary.Segment{
            expression: 256,
            size: 16
          }
        ]
      }
    ]
  ], <<255, 1, 0>>

  etudetest "should concatenate a binary", [
    render: [
      %Assign{
        name: :var,
        expression: "Robert",
        line: 1
      },
      %Binary{
        segments: [
          %Binary.Segment{
            expression: "Hello, ",
            type: :binary
          },
          %Binary.Segment{
            expression: %Var{name: :var},
            type: :binary
          }
        ],
        line: 2
      }
    ]
  ], "Hello, Robert"

  etudetest "should call a function inside a segment", [
    render: [
      %Binary{
        segments: [
          %Binary.Segment{
            type: :binary,
            expression: %Call{
              module: :erlang,
              function: :list_to_binary,
              arguments: [
                [
                  '1',
                  "2",
                  "345",
                  [
                    '6',
                    '7',
                    ["8", '9']
                  ]
                ]
              ],
              attrs: %{native: true}
            }
          }
        ]
      }
    ]
  ], "123456789"

  etudetest "should accept a variable size", [
    render: [
      %Assign{
        name: :var,
        expression: 64
      },
      %Binary{
        segments: [
          %Binary.Segment{
            expression: 1,
            size: %Var{name: :var}
          }
        ]
      }
    ]
  ], <<0, 0, 0, 0, 0, 0, 0, 1>>

end
