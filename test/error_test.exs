defmodule EtudeTest.Error do
  use EtudeTestHelper

  etudetest "should handle immediate errors", [
    render: [
      %Call{
        module: :errors,
        function: :immediate,
        line: 1
      },
    ]
  ], {:error, :immediate}

  etudetest "should handle async errors", [
    render: [
      %Call{
        module: :errors,
        function: :async,
        line: 1
      },
    ]
  ], {:error, :async}
end
