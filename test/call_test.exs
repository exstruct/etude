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

end