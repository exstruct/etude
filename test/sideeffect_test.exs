defmodule EtudeTest.SideEffect do
  use EtudeTestHelper

  etudetest "should wrap side effects", [
    render: [
      %Call{
        module: :foo,
        function: :foo
      },
      %Call{
        module: :bar,
        function: :bar
      },
      %Call{
        module: :baz,
        function: :baz
      },
      4
    ]
  ], 4
end