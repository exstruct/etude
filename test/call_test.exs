defmodule EtudeTest.Call do
  use EtudeTestHelper

  etudetest "should call a function with no arguments", [
    render: [
      %Call{
        module: :math,
        function: :zero,
      }
    ]
  ], 0

  etudetest "should call a function with static arguments", [
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

  etudetest "should memoize function calls", [
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

  etudetest "should call a native function", [
    render: [
      %Call{
        attrs: %{native: true},
        module: :erlang,
        function: :min,
        arguments: [
          18,
          21
        ]
      }
    ]
  ], 18

  etudetest "should call a returned local partial", [
    render: [
      %Call{
        module: :test,
        function: :partial,
        arguments: [
          :foo_partial,
          %{}
        ]
      }
    ],
    foo: [
      1
    ]
  ], 1

  etudetest "should call a returned local partial without state", [
    render: [
      %Call{
        module: :test,
        function: :partial_wo_state,
        arguments: [
          :foo_partial,
          %{}
        ]
      }
    ],
    foo: [
      1
    ]
  ], 1

  etudetest "should call a returned local partial with async", [
    render: [
      %Call{
        module: :test,
        function: :partial_wo_state,
        arguments: [
          :foo_partial,
          %{}
        ]
      }
    ],
    foo: [
      %Call{
        module: :test,
        function: :async,
        arguments: [
          1
        ]
      }
    ]
  ], 1

  etudetest "should call a returned remove partial", [
    render: [
      %Call{
        module: :test,
        function: :partial,
        arguments: [
          __MODULE__,
          :foo_partial,
          %{}
        ]
      }
    ],
    foo: [
      1
    ]
  ], 1

  etudetest "should call a returned remove partial without state", [
    render: [
      %Call{
        module: :test,
        function: :partial_wo_state,
        arguments: [
          __MODULE__,
          :foo_partial,
          %{}
        ]
      }
    ],
    foo: [
      1
    ]
  ], 1

end
